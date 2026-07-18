import 'package:pharos_ai_runtime/runtime/agent_registry.dart';
import 'package:pharos_ai_runtime/runtime/execution_pipeline.dart';
import 'package:pharos_ai_runtime/core/agent.dart';
import 'package:pharos_ai_runtime/core/config.dart';
import 'package:pharos_ai_runtime/core/logger.dart';
import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/hq/hq_bootstrapper.dart';
import 'package:pharos_ai_runtime/hq/hq_source.dart';
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
import 'package:pharos_ai_runtime/tooling/tool_invoker.dart';
import 'package:pharos_ai_runtime/tooling/tool_output.dart';
import 'package:pharos_ai_runtime/tooling/tool_registry.dart';

class Runtime {
  Runtime({
    required this.modelProvider,
    required RuntimeRequestBuilder requestBuilder,
    required EmployeeResponseHandler responseHandler,
    Config config = const Config(),
    AgentRegistry? registry,
    Logger logger = const Logger(),
    HQBootstrapper? bootstrap,
    ToolRegistry? toolRegistry,
    ToolInvoker? toolInvoker,
  }) : _requestBuilder = requestBuilder,
       _responseHandler = responseHandler,
       _registry = registry ?? AgentRegistry(),
       _logger = logger,
       _pipeline = ExecutionPipeline(config: config, logger: logger),
       _bootstrap = bootstrap,
       _toolRegistry = toolRegistry ?? const ToolRegistry(),
       _toolInvoker =
           toolInvoker ??
           ToolInvoker(registry: toolRegistry ?? const ToolRegistry());

  final ModelProvider modelProvider;
  final RuntimeRequestBuilder _requestBuilder;
  final EmployeeResponseHandler _responseHandler;
  final AgentRegistry _registry;
  final Logger _logger;
  final ExecutionPipeline _pipeline;
  final HQBootstrapper? _bootstrap;
  final ToolRegistry _toolRegistry;
  final ToolInvoker _toolInvoker;
  final StreamingResponseAggregator _streamingAggregator =
      StreamingResponseAggregator();

  Future<Result?> run(List<String> args, {HQSource? source}) async {
    final prepared = await _prepareExecution(args, source: source);

    if (prepared == null) {
      return null;
    }

    if (!prepared.hqPathAvailable) {
      final request = _buildModelRequest();
      // ignore: unused_local_variable
      final response = await modelProvider.generate(request);

      return _pipeline.run(prepared.agent);
    }

    if (prepared.bootFailure != null) {
      return prepared.bootFailure;
    }

    final employee = prepared.employee!;
    final request = prepared.request!;

    try {
      final response = await modelProvider.generate(request);

      if (response.toolCalls.isEmpty) {
        return await _responseHandler.handle(employee, response);
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

        toolMessages.add(
          ToolMessage(
            toolCallId: toolCall.id,
            toolName: toolCall.name,
            content: result.message,
          ),
        );
      }

      final updatedConversation = Conversation(
        messages: [
          ...request.conversation.messages,
          AssistantMessage(
            content: response.text,
            toolCalls: response.toolCalls,
          ),
          ...toolMessages,
        ],
      );

      final secondRequest = ModelRequest(
        conversation: updatedConversation,
        tools: _toolRegistry.definitions(),
        toolOutputs: toolOutputs,
      );

      final secondResponse = await modelProvider.generate(secondRequest);

      return await _responseHandler.handle(employee, secondResponse);
    } on ModelException catch (e) {
      return Result.failure(e.message);
    }
  }

  /// Builds a ModelRequest and delegates streaming execution to the
  /// configured ModelProvider.
  Future<StreamingResponse?> stream(
    List<String> args,
    ModelConfig modelConfig, {
    HQSource? source,
  }) async {
    final prepared = await _prepareExecution(args, source: source);

    if (prepared == null || !prepared.isReady) {
      return null;
    }

    return modelProvider.stream(prepared.request!, modelConfig);
  }

  /// Shared execution preparation for run() and stream(): validates args,
  /// resolves the agent, boots HQ (when configured), resolves the matching
  /// employee, and builds the ModelRequest. Returns null when args are
  /// invalid or the agent is unknown (both callers return null in that
  /// case). When no HQ bootstrap/source is configured,
  /// [_PreparedExecution.hqPathAvailable] is false and only [run] falls
  /// back to its legacy pipeline; [stream] has no such fallback.
  Future<_PreparedExecution?> _prepareExecution(
    List<String> args, {
    HQSource? source,
  }) async {
    if (args.isEmpty) {
      _logger.info('Usage:');
      _logger.info('pharos marketing');
      return null;
    }

    final agent = _registry.find(args.first);

    if (agent == null) {
      _logger.warning('Unknown agent.');
      return null;
    }

    if (_bootstrap == null || source == null) {
      return _PreparedExecution.noHQPath(agent);
    }

    final bootResult = await _bootstrap.boot(source);

    if (!bootResult.result.success) {
      return _PreparedExecution.failed(agent, bootResult.result);
    }

    EmployeeRuntime? selectedEmployee;

    for (final employee in bootResult.employees) {
      if (employee.definition.id == args.first) {
        selectedEmployee = employee;
        break;
      }
    }

    if (selectedEmployee == null) {
      return _PreparedExecution.failed(
        agent,
        Result.failure('Employee "${args.first}" not found.'),
      );
    }

    final request = _requestBuilder.build(
      selectedEmployee,
      tools: _toolRegistry.definitions(),
    );

    return _PreparedExecution.ready(agent, selectedEmployee, request);
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

  ModelRequest _buildModelRequest() {
    return const ModelRequest(
      conversation: Conversation(
        messages: [
          SystemMessage(content: ''),
          UserMessage(content: ''),
        ],
      ),
    );
  }
}

/// Result of [Runtime._prepareExecution]: everything run() and stream()
/// need after shared preparation, plus enough state for each to reproduce
/// its own pre-existing fallback/failure behavior.
class _PreparedExecution {
  const _PreparedExecution._({
    required this.agent,
    required this.hqPathAvailable,
    this.employee,
    this.request,
    this.bootFailure,
  });

  const _PreparedExecution.noHQPath(Agent agent)
    : this._(agent: agent, hqPathAvailable: false);

  const _PreparedExecution.failed(Agent agent, Result failure)
    : this._(agent: agent, hqPathAvailable: true, bootFailure: failure);

  const _PreparedExecution.ready(
    Agent agent,
    EmployeeRuntime employee,
    ModelRequest request,
  ) : this._(
        agent: agent,
        hqPathAvailable: true,
        employee: employee,
        request: request,
      );

  final Agent agent;
  final bool hqPathAvailable;
  final EmployeeRuntime? employee;
  final ModelRequest? request;
  final Result? bootFailure;

  bool get isReady => employee != null && request != null;
}
