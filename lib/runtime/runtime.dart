import 'dart:async';

import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/memory/conversation_memory.dart';
import 'package:pharos_ai_runtime/models/conversation.dart';
import 'package:pharos_ai_runtime/models/model_config.dart';
import 'package:pharos_ai_runtime/models/model_exception.dart';
import 'package:pharos_ai_runtime/models/model_provider.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/models/model_response.dart';
import 'package:pharos_ai_runtime/models/streaming_response.dart';
import 'package:pharos_ai_runtime/runtime/employee_response_handler.dart';
import 'package:pharos_ai_runtime/runtime/employee_runtime.dart';
import 'package:pharos_ai_runtime/runtime/runtime_request_builder.dart';
import 'package:pharos_ai_runtime/runtime/streaming_response_aggregator.dart';
import 'package:pharos_ai_runtime/runtime/tool_call_reconstructor.dart';
import 'package:pharos_ai_runtime/tooling/tool_call.dart';
import 'package:pharos_ai_runtime/tooling/tool_invoker.dart';
import 'package:pharos_ai_runtime/tooling/tool_output.dart';
import 'package:pharos_ai_runtime/tooling/tool_registry.dart';

/// Executes an already-resolved [EmployeeRuntime]. Runtime owns execution
/// only: it never looks up Employees by id, never boots an HQ, and never
/// knows what an Employee is called or where it came from. Resolving which
/// Employee to run is the caller's (HQ's) responsibility.
class Runtime {
  Runtime({
    required this.modelProvider,
    required RuntimeRequestBuilder requestBuilder,
    required EmployeeResponseHandler responseHandler,
    ToolRegistry? toolRegistry,
    ToolInvoker? toolInvoker,
  }) : _requestBuilder = requestBuilder,
       _responseHandler = responseHandler,
       _toolRegistry = toolRegistry ?? const ToolRegistry(),
       _toolInvoker =
           toolInvoker ??
           ToolInvoker(registry: toolRegistry ?? const ToolRegistry());

  final ModelProvider modelProvider;
  final RuntimeRequestBuilder _requestBuilder;
  final EmployeeResponseHandler _responseHandler;
  final ToolRegistry _toolRegistry;
  final ToolInvoker _toolInvoker;
  final StreamingResponseAggregator _streamingAggregator =
      StreamingResponseAggregator();

  /// Executes [employeeRuntime]. When [memory] is given, every
  /// UserMessage, AssistantMessage, and ToolMessage produced during
  /// execution is automatically recorded into it, in order (SystemMessage
  /// is never recorded — Memory tracks the conversation's turns, not the
  /// static system prompt). Recording is a pure side effect: it never
  /// changes what is returned or how execution proceeds.
  Future<Result> run(
    EmployeeRuntime employeeRuntime, {
    ConversationMemory? memory,
  }) async {
    final request = _requestBuilder.build(
      employeeRuntime,
      tools: _toolRegistry.definitions(),
    );

    if (memory != null) {
      for (final message in request.conversation.messages) {
        await memory.record(message);
      }
    }

    try {
      final response = await modelProvider.generate(request);
      final assistantMessage = AssistantMessage(
        content: response.text,
        toolCalls: response.toolCalls,
      );

      if (memory != null) {
        await memory.record(assistantMessage);
      }

      if (response.toolCalls.isEmpty) {
        return await _responseHandler.handle(employeeRuntime, response);
      }

      final toolOutputs = <ToolOutput>[];
      final toolMessages = <ToolMessage>[];

      for (final toolCall in response.toolCalls) {
        final result = await _toolInvoker.invoke(toolCall);

        toolOutputs.add(
          ToolOutput(
            toolCallId: toolCall.id,
            toolName: toolCall.name,
            success: result.success,
            content: result.message,
          ),
        );

        final toolMessage = ToolMessage(
          toolCallId: toolCall.id,
          toolName: toolCall.name,
          content: result.message,
        );

        toolMessages.add(toolMessage);

        if (memory != null) {
          await memory.record(toolMessage);
        }
      }

      final updatedConversation = Conversation(
        messages: [
          ...request.conversation.messages,
          assistantMessage,
          ...toolMessages,
        ],
      );

      final secondRequest = ModelRequest(
        conversation: updatedConversation,
        tools: _toolRegistry.definitions(),
        toolOutputs: toolOutputs,
      );

      final secondResponse = await modelProvider.generate(secondRequest);

      if (memory != null) {
        await memory.record(
          AssistantMessage(
            content: secondResponse.text,
            toolCalls: secondResponse.toolCalls,
          ),
        );
      }

      return await _responseHandler.handle(employeeRuntime, secondResponse);
    } on ModelException catch (e) {
      return Result.failure(e.message);
    }
  }

  /// Builds a ModelRequest and delegates streaming execution to the
  /// configured ModelProvider.
  Future<StreamingResponse> stream(
    EmployeeRuntime employeeRuntime,
    ModelConfig modelConfig,
  ) async {
    final request = _requestBuilder.build(
      employeeRuntime,
      tools: _toolRegistry.definitions(),
    );

    return _streamPipeline(request, modelConfig);
  }

  /// Internal Runtime streaming pipeline: calls ModelProvider.stream() and
  /// wraps the result in a Runtime-owned StreamingResponse. Every chunk is
  /// forwarded unchanged; ToolCalls are reconstructed and executed
  /// internally as they complete. If any ToolCalls were executed, one
  /// follow-up ModelProvider.stream() call continues generation with the
  /// updated Conversation, and its chunks are forwarded as part of the same
  /// continuous stream — without changing stream()'s public contract.
  Future<StreamingResponse> _streamPipeline(
    ModelRequest request,
    ModelConfig modelConfig,
  ) async {
    final providerStream = await modelProvider.stream(request, modelConfig);

    return _RuntimeStreamingResponse(
      providerStream,
      modelProvider,
      _toolInvoker,
      request,
      modelConfig,
    );
  }

  /// Internal streaming pipeline: ModelProvider.stream() ->
  /// StreamingResponseAggregator -> ModelResponse. Not wired into run();
  /// no public streaming API is exposed by this.
  Future<ModelResponse> streamAndAggregate(
    ModelRequest request,
    ModelConfig modelConfig,
  ) async {
    final streamingResponse = await modelProvider.stream(request, modelConfig);

    return _streamingAggregator.aggregate(streamingResponse);
  }
}

/// Runtime-owned StreamingResponse returned by [Runtime._streamPipeline].
/// Forwards every chunk from the underlying provider StreamingResponse
/// unchanged, while observing each chunk through a [ToolCallReconstructor],
/// executing each ToolCall via [ToolInvoker] as soon as it completes, and
/// recording what happened as AssistantMessage/ToolMessage pairs appended
/// to the Conversation the request was built from. If any ToolCalls were
/// executed once the first provider stream ends, one follow-up
/// ModelProvider.stream() call continues generation with the updated
/// Conversation, and its chunks are forwarded as part of the same
/// continuous stream — with no further ToolCall processing, so at most one
/// additional model request is ever made.
class _RuntimeStreamingResponse implements StreamingResponse {
  _RuntimeStreamingResponse(
    StreamingResponse source,
    ModelProvider modelProvider,
    ToolInvoker toolInvoker,
    ModelRequest request,
    ModelConfig modelConfig,
  ) {
    _messages.addAll(request.conversation.messages);
    stream = _forward(
      source,
      _reconstructor,
      modelProvider,
      toolInvoker,
      request,
      modelConfig,
      _toolOutputs,
      _messages,
      _toolCallsCompleter,
      _toolOutputsCompleter,
      _conversationCompleter,
    );
  }

  final ToolCallReconstructor _reconstructor = ToolCallReconstructor();
  final List<ToolOutput> _toolOutputs = [];
  final List<Message> _messages = [];
  final Completer<List<ToolCall>> _toolCallsCompleter =
      Completer<List<ToolCall>>();
  final Completer<List<ToolOutput>> _toolOutputsCompleter =
      Completer<List<ToolOutput>>();
  final Completer<Conversation> _conversationCompleter =
      Completer<Conversation>();

  @override
  late final Stream<ModelResponseChunk> stream;

  /// Resolves once the first provider stream has been fully observed, with
  /// every ToolCall fragment merged into its complete form. Internal to
  /// Runtime only — not part of the public StreamingResponse contract.
  Future<List<ToolCall>> get reconstructedToolCalls =>
      _toolCallsCompleter.future;

  /// Resolves once every reconstructed ToolCall has executed. Internal to
  /// Runtime only — not part of the public StreamingResponse contract.
  Future<List<ToolOutput>> get toolOutputs => _toolOutputsCompleter.future;

  /// Resolves once the first provider stream ends, to the original
  /// Conversation extended with one AssistantMessage/ToolMessage pair per
  /// executed ToolCall, in execution order. Internal to Runtime only — not
  /// part of the public StreamingResponse contract.
  Future<Conversation> get conversation => _conversationCompleter.future;

  static Stream<ModelResponseChunk> _forward(
    StreamingResponse source,
    ToolCallReconstructor reconstructor,
    ModelProvider modelProvider,
    ToolInvoker toolInvoker,
    ModelRequest request,
    ModelConfig modelConfig,
    List<ToolOutput> toolOutputs,
    List<Message> messages,
    Completer<List<ToolCall>> toolCallsCompleter,
    Completer<List<ToolOutput>> toolOutputsCompleter,
    Completer<Conversation> conversationCompleter,
  ) async* {
    await for (final chunk in source.stream) {
      reconstructor.observe(chunk);

      for (final toolCall in reconstructor.drainCompleted()) {
        await _executeAndRecord(toolInvoker, toolCall, toolOutputs, messages);
      }

      yield chunk;
    }

    for (final toolCall in reconstructor.drainRemaining()) {
      await _executeAndRecord(toolInvoker, toolCall, toolOutputs, messages);
    }

    if (!toolCallsCompleter.isCompleted) {
      toolCallsCompleter.complete(reconstructor.complete());
    }

    if (!toolOutputsCompleter.isCompleted) {
      toolOutputsCompleter.complete(toolOutputs);
    }

    if (!conversationCompleter.isCompleted) {
      conversationCompleter.complete(
        Conversation(messages: List.unmodifiable(messages)),
      );
    }

    if (toolOutputs.isEmpty) {
      return;
    }

    final secondRequest = ModelRequest(
      conversation: Conversation(messages: List.unmodifiable(messages)),
      tools: request.tools,
    );

    final secondProviderStream = await modelProvider.stream(
      secondRequest,
      modelConfig,
    );

    yield* secondProviderStream.stream;
  }

  static Future<void> _executeAndRecord(
    ToolInvoker toolInvoker,
    ToolCall toolCall,
    List<ToolOutput> toolOutputs,
    List<Message> messages,
  ) async {
    final result = await toolInvoker.invoke(toolCall);

    final output = ToolOutput(
      toolCallId: toolCall.id,
      toolName: toolCall.name,
      success: result.success,
      content: result.message,
    );

    toolOutputs.add(output);

    messages.add(AssistantMessage(content: '', toolCalls: [toolCall]));
    messages.add(
      ToolMessage(
        toolCallId: output.toolCallId,
        toolName: output.toolName,
        content: output.content,
      ),
    );
  }
}
