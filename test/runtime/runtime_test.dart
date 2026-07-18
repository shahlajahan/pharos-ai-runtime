import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/employees/employee_definition.dart';
import 'package:pharos_ai_runtime/memory/conversation_memory.dart';
import 'package:pharos_ai_runtime/memory/memory_author.dart';
import 'package:pharos_ai_runtime/models/conversation.dart';
import 'package:pharos_ai_runtime/models/mock_model_provider.dart';
import 'package:pharos_ai_runtime/models/model_config.dart';
import 'package:pharos_ai_runtime/models/model_exception.dart';
import 'package:pharos_ai_runtime/models/model_provider.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/models/model_response.dart';
import 'package:pharos_ai_runtime/models/openai_exception.dart';
import 'package:pharos_ai_runtime/models/streaming_response.dart';
import 'package:pharos_ai_runtime/runtime/default_employee_response_handler.dart';
import 'package:pharos_ai_runtime/runtime/default_runtime_request_builder.dart';
import 'package:pharos_ai_runtime/runtime/employee_response_handler.dart';
import 'package:pharos_ai_runtime/runtime/employee_runtime.dart';
import 'package:pharos_ai_runtime/runtime/runtime.dart';
import 'package:pharos_ai_runtime/runtime/runtime_request_builder.dart';
import 'package:pharos_ai_runtime/tooling/tool.dart';
import 'package:pharos_ai_runtime/tooling/tool_call.dart';
import 'package:pharos_ai_runtime/tooling/tool_context.dart';
import 'package:pharos_ai_runtime/tooling/tool_definition.dart';
import 'package:pharos_ai_runtime/tooling/tool_invoker.dart';
import 'package:pharos_ai_runtime/tooling/tool_output.dart';
import 'package:pharos_ai_runtime/tooling/tool_registry.dart';
import 'package:test/test.dart';

class _SpyModelProvider extends MockModelProvider {
  int callCount = 0;
  ModelRequest? capturedRequest;
  ModelResponse? returnedResponse;

  @override
  Future<ModelResponse> generate(ModelRequest request) async {
    callCount++;
    capturedRequest = request;

    final response = await super.generate(request);
    returnedResponse = response;

    return response;
  }
}

class _SpyRuntimeRequestBuilder extends RuntimeRequestBuilder {
  int callCount = 0;
  EmployeeRuntime? capturedEmployee;
  List<ToolDefinition>? capturedTools;
  List<ToolOutput>? capturedToolOutputs;

  @override
  ModelRequest build(
    EmployeeRuntime employee, {
    List<ToolDefinition> tools = const [],
    List<ToolOutput> toolOutputs = const [],
  }) {
    callCount++;
    capturedEmployee = employee;
    capturedTools = tools;
    capturedToolOutputs = toolOutputs;

    return const ModelRequest(conversation: Conversation());
  }
}

class _SpyEmployeeResponseHandler extends EmployeeResponseHandler {
  Result result = Result.success('handled');
  int callCount = 0;
  EmployeeRuntime? capturedEmployee;
  ModelResponse? capturedResponse;

  @override
  Future<Result> handle(
    EmployeeRuntime employee,
    ModelResponse response,
  ) async {
    callCount++;
    capturedEmployee = employee;
    capturedResponse = response;

    return result;
  }
}

class _OpenAIExceptionModelProvider extends ModelProvider {
  @override
  Future<ModelResponse> generate(ModelRequest request) async {
    throw const OpenAIException('rate limit exceeded');
  }
}

class _CustomModelExceptionModelProvider extends ModelProvider {
  @override
  Future<ModelResponse> generate(ModelRequest request) async {
    throw const ModelException('custom model failure');
  }
}

class _StateErrorModelProvider extends ModelProvider {
  @override
  Future<ModelResponse> generate(ModelRequest request) async {
    throw StateError('boom');
  }
}

class _FormatExceptionModelProvider extends ModelProvider {
  @override
  Future<ModelResponse> generate(ModelRequest request) async {
    throw const FormatException('bad format');
  }
}

class _NoopTool extends Tool {
  @override
  String get id => 'noop';

  @override
  Future<Result> execute(ToolContext context) async {
    return Result.success('noop');
  }
}

class _ConfigurableModelProvider extends ModelProvider {
  ModelResponse response = const ModelResponse(text: 'ok');

  @override
  Future<ModelResponse> generate(ModelRequest request) async => response;
}

class _TwoStepModelProvider extends ModelProvider {
  int callCount = 0;
  List<ModelRequest> capturedRequests = [];
  ModelResponse firstResponse = const ModelResponse(text: 'first');
  ModelResponse secondResponse = const ModelResponse(text: 'second');

  @override
  Future<ModelResponse> generate(ModelRequest request) async {
    callCount++;
    capturedRequests.add(request);

    return callCount == 1 ? firstResponse : secondResponse;
  }
}

class _FakeStreamingResponse implements StreamingResponse {
  const _FakeStreamingResponse(this.stream);

  @override
  final Stream<ModelResponseChunk> stream;
}

class _StreamingModelProvider extends ModelProvider {
  ModelResponse generateResponse = const ModelResponse(text: 'ok');
  List<ModelResponseChunk> chunks = const [];
  // Returned by the second stream() call (the streaming Tool-loop
  // follow-up request), if one is made. Defaults to empty so existing
  // single-round tests are unaffected unless they opt in.
  List<ModelResponseChunk> secondChunks = const [];
  int streamCallCount = 0;
  ModelRequest? capturedStreamRequest;
  final List<ModelRequest> capturedStreamRequests = [];
  ModelConfig? capturedStreamModelConfig;
  StreamingResponse? returnedStreamingResponse;

  @override
  Future<ModelResponse> generate(ModelRequest request) async =>
      generateResponse;

  @override
  Future<StreamingResponse> stream(
    ModelRequest request,
    ModelConfig modelConfig,
  ) async {
    streamCallCount++;
    capturedStreamRequest = request;
    capturedStreamRequests.add(request);
    capturedStreamModelConfig = modelConfig;

    final chunksForThisCall = streamCallCount == 1 ? chunks : secondChunks;
    final response = _FakeStreamingResponse(
      Stream.fromIterable(chunksForThisCall),
    );
    returnedStreamingResponse = response;

    return response;
  }
}

class _SpyToolInvoker extends ToolInvoker {
  _SpyToolInvoker() : super(registry: const ToolRegistry());

  final List<ToolCall> invokedToolCalls = [];

  @override
  Future<Result> invoke(ToolCall toolCall) async {
    invokedToolCalls.add(toolCall);

    return Result.success('invoked ${toolCall.name}');
  }
}

class _FailingSpyToolInvoker extends ToolInvoker {
  _FailingSpyToolInvoker() : super(registry: const ToolRegistry());

  final List<ToolCall> invokedToolCalls = [];

  @override
  Future<Result> invoke(ToolCall toolCall) async {
    invokedToolCalls.add(toolCall);

    return Result.failure('${toolCall.name} failed');
  }
}

void main() {
  const employee = EmployeeRuntime(
    definition: EmployeeDefinition(
      id: 'marketing',
      name: 'Marketing Employee',
      role: 'Marketing',
    ),
    knowledge: [],
    prompts: [],
  );

  test('Runtime accepts a ModelProvider', () {
    final modelProvider = MockModelProvider();

    final runtime = Runtime(
      modelProvider: modelProvider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
    );

    expect(runtime.modelProvider, same(modelProvider));
  });

  test(
    'Runtime executes the given EmployeeRuntime and returns a Result',
    () async {
      final runtime = Runtime(
        modelProvider: MockModelProvider(),
        requestBuilder: DefaultRuntimeRequestBuilder(),
        responseHandler: DefaultEmployeeResponseHandler(),
      );

      final result = await runtime.run(employee);

      expect(result.success, isTrue);
    },
  );

  test(
    'Runtime delegates request creation to RuntimeRequestBuilder, calling '
    'build() exactly once with the given EmployeeRuntime unchanged',
    () async {
      final requestBuilder = _SpyRuntimeRequestBuilder();
      final runtime = Runtime(
        modelProvider: MockModelProvider(),
        requestBuilder: requestBuilder,
        responseHandler: DefaultEmployeeResponseHandler(),
      );

      await runtime.run(employee);

      expect(requestBuilder.callCount, 1);
      expect(requestBuilder.capturedEmployee, same(employee));
    },
  );

  test('Runtime calls modelProvider.generate() exactly once', () async {
    final modelProvider = _SpyModelProvider();
    final runtime = Runtime(
      modelProvider: modelProvider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
    );

    await runtime.run(employee);

    expect(modelProvider.callCount, 1);
  });

  test('Runtime calls EmployeeResponseHandler.handle() exactly once, '
      'forwarding the given EmployeeRuntime and generated ModelResponse '
      'unchanged', () async {
    final modelProvider = _SpyModelProvider();
    final responseHandler = _SpyEmployeeResponseHandler();
    final runtime = Runtime(
      modelProvider: modelProvider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: responseHandler,
    );

    await runtime.run(employee);

    expect(responseHandler.callCount, 1);
    expect(responseHandler.capturedEmployee, same(employee));
    expect(
      responseHandler.capturedResponse,
      same(modelProvider.returnedResponse),
    );
  });

  test(
    'Runtime returns exactly the Result returned by EmployeeResponseHandler',
    () async {
      final responseHandler = _SpyEmployeeResponseHandler()
        ..result = Result.failure('handler failure');
      final runtime = Runtime(
        modelProvider: MockModelProvider(),
        requestBuilder: DefaultRuntimeRequestBuilder(),
        responseHandler: responseHandler,
      );

      final result = await runtime.run(employee);

      expect(result, same(responseHandler.result));
    },
  );

  test('Runtime returns the handler Result when the ModelProvider '
      'succeeds', () async {
    final runtime = Runtime(
      modelProvider: MockModelProvider(),
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
    );

    final result = await runtime.run(employee);

    expect(result.success, isTrue);
  });

  test(
    'Runtime converts OpenAIException into Result.failure(message)',
    () async {
      final runtime = Runtime(
        modelProvider: _OpenAIExceptionModelProvider(),
        requestBuilder: DefaultRuntimeRequestBuilder(),
        responseHandler: DefaultEmployeeResponseHandler(),
      );

      final result = await runtime.run(employee);

      expect(result.success, isFalse);
      expect(result.message, 'rate limit exceeded');
    },
  );

  test('Runtime converts any ModelException (not just OpenAIException) into '
      'Result.failure(message)', () async {
    final runtime = Runtime(
      modelProvider: _CustomModelExceptionModelProvider(),
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
    );

    final result = await runtime.run(employee);

    expect(result.success, isFalse);
    expect(result.message, 'custom model failure');
  });

  test('Runtime lets StateError propagate uncaught', () async {
    final runtime = Runtime(
      modelProvider: _StateErrorModelProvider(),
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
    );

    expect(() => runtime.run(employee), throwsA(isA<StateError>()));
  });

  test('Runtime lets FormatException propagate uncaught', () async {
    final runtime = Runtime(
      modelProvider: _FormatExceptionModelProvider(),
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
    );

    expect(() => runtime.run(employee), throwsA(isA<FormatException>()));
  });

  test(
    'Runtime accepts a custom ToolRegistry without changing behavior',
    () async {
      final runtime = Runtime(
        modelProvider: MockModelProvider(),
        requestBuilder: DefaultRuntimeRequestBuilder(),
        responseHandler: DefaultEmployeeResponseHandler(),
        toolRegistry: ToolRegistry(tools: {'noop': _NoopTool()}),
      );

      final result = await runtime.run(employee);

      expect(result.success, isTrue);
    },
  );

  test('Runtime constructs successfully without providing a ToolRegistry', () {
    expect(
      () => Runtime(
        modelProvider: MockModelProvider(),
        requestBuilder: DefaultRuntimeRequestBuilder(),
        responseHandler: DefaultEmployeeResponseHandler(),
      ),
      returnsNormally,
    );
  });

  test(
    'Runtime forwards ToolRegistry.definitions() into RuntimeRequestBuilder',
    () async {
      const definition = ToolDefinition(
        id: 'search',
        description: 'Search the web.',
      );
      final requestBuilder = _SpyRuntimeRequestBuilder();
      final runtime = Runtime(
        modelProvider: MockModelProvider(),
        requestBuilder: requestBuilder,
        responseHandler: DefaultEmployeeResponseHandler(),
        toolRegistry: const ToolRegistry(definitions: {'search': definition}),
      );

      await runtime.run(employee);

      expect(requestBuilder.capturedTools, [definition]);
    },
  );

  test(
    'Runtime forwards an empty tool list when no ToolRegistry is provided',
    () async {
      final requestBuilder = _SpyRuntimeRequestBuilder();
      final runtime = Runtime(
        modelProvider: MockModelProvider(),
        requestBuilder: requestBuilder,
        responseHandler: DefaultEmployeeResponseHandler(),
      );

      await runtime.run(employee);

      expect(requestBuilder.capturedTools, isEmpty);
    },
  );

  test(
    'Runtime never invokes ToolInvoker when response.toolCalls is empty',
    () async {
      final toolInvoker = _SpyToolInvoker();
      final runtime = Runtime(
        modelProvider: _ConfigurableModelProvider(),
        requestBuilder: DefaultRuntimeRequestBuilder(),
        responseHandler: DefaultEmployeeResponseHandler(),
        toolInvoker: toolInvoker,
      );

      await runtime.run(employee);

      expect(toolInvoker.invokedToolCalls, isEmpty);
    },
  );

  test('Runtime executes a single tool call once', () async {
    final modelProvider = _ConfigurableModelProvider()
      ..response = const ModelResponse(
        text: 'ok',
        toolCalls: [ToolCall(id: 'call_1', name: 'search', arguments: '{}')],
      );
    final toolInvoker = _SpyToolInvoker();
    final runtime = Runtime(
      modelProvider: modelProvider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
      toolInvoker: toolInvoker,
    );

    await runtime.run(employee);

    expect(toolInvoker.invokedToolCalls.map((call) => call.name), ['search']);
  });

  test('Runtime executes multiple tool calls sequentially, in order', () async {
    final modelProvider = _ConfigurableModelProvider()
      ..response = const ModelResponse(
        text: 'ok',
        toolCalls: [
          ToolCall(id: 'call_1', name: 'search', arguments: '{}'),
          ToolCall(id: 'call_2', name: 'calculator', arguments: '{}'),
        ],
      );
    final toolInvoker = _SpyToolInvoker();
    final runtime = Runtime(
      modelProvider: modelProvider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
      toolInvoker: toolInvoker,
    );

    await runtime.run(employee);

    expect(toolInvoker.invokedToolCalls.map((call) => call.name), [
      'search',
      'calculator',
    ]);
  });

  test(
    'Runtime forwards the original ToolCall unchanged into ToolInvoker',
    () async {
      const toolCall = ToolCall(
        id: 'call_1',
        name: 'search',
        arguments: '{"query":"Paris"}',
      );
      final modelProvider = _ConfigurableModelProvider()
        ..response = const ModelResponse(text: 'ok', toolCalls: [toolCall]);
      final toolInvoker = _SpyToolInvoker();
      final runtime = Runtime(
        modelProvider: modelProvider,
        requestBuilder: DefaultRuntimeRequestBuilder(),
        responseHandler: DefaultEmployeeResponseHandler(),
        toolInvoker: toolInvoker,
      );

      await runtime.run(employee);

      expect(toolInvoker.invokedToolCalls, [same(toolCall)]);
    },
  );

  test('Runtime still returns the response-handler Result when tool calls '
      'exist', () async {
    final modelProvider = _ConfigurableModelProvider()
      ..response = const ModelResponse(
        text: 'ok',
        toolCalls: [ToolCall(id: 'call_1', name: 'search', arguments: '{}')],
      );
    final responseHandler = _SpyEmployeeResponseHandler()
      ..result = Result.success('handled with tools');
    final runtime = Runtime(
      modelProvider: modelProvider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: responseHandler,
      toolInvoker: _SpyToolInvoker(),
    );

    final result = await runtime.run(employee);

    expect(result, same(responseHandler.result));
  });

  test('Runtime does not crash when tool execution fails, and still returns '
      'the original Result, exactly as ToolInvoker already defines', () async {
    final modelProvider = _ConfigurableModelProvider()
      ..response = const ModelResponse(
        text: 'ok',
        toolCalls: [
          ToolCall(id: 'call_1', name: 'unregistered-tool', arguments: '{}'),
        ],
      );
    final runtime = Runtime(
      modelProvider: modelProvider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
      toolInvoker: ToolInvoker(registry: const ToolRegistry()),
    );

    final result = await runtime.run(employee);

    expect(result.success, isTrue);
  });

  test('Runtime still invokes every tool call, and still returns the '
      'response-handler Result, even when tool executions fail', () async {
    final modelProvider = _ConfigurableModelProvider()
      ..response = const ModelResponse(
        text: 'ok',
        toolCalls: [
          ToolCall(id: 'call_1', name: 'search', arguments: '{}'),
          ToolCall(id: 'call_2', name: 'calculator', arguments: '{}'),
        ],
      );
    final toolInvoker = _FailingSpyToolInvoker();
    final responseHandler = _SpyEmployeeResponseHandler()
      ..result = Result.success('handled despite tool failures');
    final runtime = Runtime(
      modelProvider: modelProvider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: responseHandler,
      toolInvoker: toolInvoker,
    );

    final result = await runtime.run(employee);

    expect(toolInvoker.invokedToolCalls.map((call) => call.name), [
      'search',
      'calculator',
    ]);
    expect(result, same(responseHandler.result));
  });

  test('Runtime calls modelProvider.generate() exactly once when no tool '
      'calls exist', () async {
    final modelProvider = _TwoStepModelProvider()
      ..firstResponse = const ModelResponse(text: 'ok');
    final runtime = Runtime(
      modelProvider: modelProvider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
    );

    await runtime.run(employee);

    expect(modelProvider.callCount, 1);
  });

  test('Runtime calls modelProvider.generate() exactly twice when tool '
      'calls exist', () async {
    final modelProvider = _TwoStepModelProvider()
      ..firstResponse = const ModelResponse(
        text: '',
        toolCalls: [ToolCall(id: 'call_1', name: 'search', arguments: '{}')],
      )
      ..secondResponse = const ModelResponse(text: 'final answer');
    final runtime = Runtime(
      modelProvider: modelProvider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
    );

    await runtime.run(employee);

    expect(modelProvider.callCount, 2);
  });

  test('Runtime sends every ToolOutput in the second request, preserving '
      'toolCallId and toolName', () async {
    const toolCall1 = ToolCall(id: 'call_1', name: 'search', arguments: '{}');
    const toolCall2 = ToolCall(
      id: 'call_2',
      name: 'calculator',
      arguments: '{}',
    );
    final modelProvider = _TwoStepModelProvider()
      ..firstResponse = const ModelResponse(
        text: '',
        toolCalls: [toolCall1, toolCall2],
      )
      ..secondResponse = const ModelResponse(text: 'final answer');
    final runtime = Runtime(
      modelProvider: modelProvider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
    );

    await runtime.run(employee);

    final secondRequest = modelProvider.capturedRequests[1];
    expect(secondRequest.toolOutputs, hasLength(2));
    expect(secondRequest.toolOutputs[0].toolCallId, 'call_1');
    expect(secondRequest.toolOutputs[0].toolName, 'search');
    expect(secondRequest.toolOutputs[1].toolCallId, 'call_2');
    expect(secondRequest.toolOutputs[1].toolName, 'calculator');
  });

  test('Runtime passes the second ModelResponse into EmployeeResponseHandler '
      'when tool calls were executed', () async {
    const secondResponse = ModelResponse(text: 'final answer');
    final modelProvider = _TwoStepModelProvider()
      ..firstResponse = const ModelResponse(
        text: '',
        toolCalls: [ToolCall(id: 'call_1', name: 'search', arguments: '{}')],
      )
      ..secondResponse = secondResponse;
    final responseHandler = _SpyEmployeeResponseHandler();
    final runtime = Runtime(
      modelProvider: modelProvider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: responseHandler,
    );

    await runtime.run(employee);

    expect(responseHandler.capturedResponse, same(secondResponse));
  });

  test('Runtime appends an AssistantMessage with the response content and '
      'toolCalls after tool execution', () async {
    final modelProvider = _TwoStepModelProvider()
      ..firstResponse = const ModelResponse(
        text: 'let me check',
        toolCalls: [ToolCall(id: 'call_1', name: 'search', arguments: '{}')],
      )
      ..secondResponse = const ModelResponse(text: 'final answer');
    final runtime = Runtime(
      modelProvider: modelProvider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
    );

    await runtime.run(employee);

    final firstRequest = modelProvider.capturedRequests[0];
    final secondRequest = modelProvider.capturedRequests[1];
    final firstLength = firstRequest.conversation.messages.length;

    final assistantMessage =
        secondRequest.conversation.messages[firstLength] as AssistantMessage;

    expect(assistantMessage.content, 'let me check');
    expect(
      assistantMessage.toolCalls,
      same(modelProvider.firstResponse.toolCalls),
    );
  });

  test('Runtime appends a ToolMessage per executed tool call, after the '
      'AssistantMessage and in ToolCall order', () async {
    const toolCall1 = ToolCall(id: 'call_1', name: 'search', arguments: '{}');
    const toolCall2 = ToolCall(
      id: 'call_2',
      name: 'calculator',
      arguments: '{}',
    );
    final modelProvider = _TwoStepModelProvider()
      ..firstResponse = const ModelResponse(
        text: '',
        toolCalls: [toolCall1, toolCall2],
      )
      ..secondResponse = const ModelResponse(text: 'final answer');
    final toolInvoker = _SpyToolInvoker();
    final runtime = Runtime(
      modelProvider: modelProvider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
      toolInvoker: toolInvoker,
    );

    await runtime.run(employee);

    final secondRequest = modelProvider.capturedRequests[1];
    final firstLength =
        modelProvider.capturedRequests[0].conversation.messages.length;
    final messagesAfterAssistant = secondRequest.conversation.messages.sublist(
      firstLength + 1,
    );

    expect(messagesAfterAssistant, hasLength(2));

    final toolMessage1 = messagesAfterAssistant[0] as ToolMessage;
    final toolMessage2 = messagesAfterAssistant[1] as ToolMessage;

    expect(toolMessage1.toolCallId, 'call_1');
    expect(toolMessage1.toolName, 'search');
    expect(toolMessage1.content, 'invoked search');
    expect(toolMessage2.toolCallId, 'call_2');
    expect(toolMessage2.toolName, 'calculator');
    expect(toolMessage2.content, 'invoked calculator');
  });

  test('Runtime creates the second ModelRequest from the updated Conversation, '
      'preserving the original conversation prefix unchanged', () async {
    final modelProvider = _TwoStepModelProvider()
      ..firstResponse = const ModelResponse(
        text: '',
        toolCalls: [ToolCall(id: 'call_1', name: 'search', arguments: '{}')],
      )
      ..secondResponse = const ModelResponse(text: 'final answer');
    final runtime = Runtime(
      modelProvider: modelProvider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
    );

    await runtime.run(employee);

    final firstRequest = modelProvider.capturedRequests[0];
    final secondRequest = modelProvider.capturedRequests[1];
    final firstLength = firstRequest.conversation.messages.length;

    expect(
      secondRequest.conversation.messages.sublist(0, firstLength),
      orderedEquals(firstRequest.conversation.messages),
    );
    expect(secondRequest.conversation.messages.length, firstLength + 2);
  });

  test('Runtime makes no second request when no tool calls exist', () async {
    final modelProvider = _TwoStepModelProvider()
      ..firstResponse = const ModelResponse(text: 'ok');
    final runtime = Runtime(
      modelProvider: modelProvider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
    );

    await runtime.run(employee);

    expect(modelProvider.capturedRequests, hasLength(1));
  });

  test('run() does not record into memory when none is given', () async {
    final runtime = Runtime(
      modelProvider: MockModelProvider(),
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
    );

    // No memory passed; only asserting run() completes normally without one.
    final result = await runtime.run(employee);

    expect(result.success, isTrue);
  });

  test('run() records the UserMessage and AssistantMessage into the given '
      'memory when no tool calls exist, excluding the SystemMessage', () async {
    final memory = ConversationMemory();
    final modelProvider = _ConfigurableModelProvider()
      ..response = const ModelResponse(text: 'final answer');
    final runtime = Runtime(
      modelProvider: modelProvider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
    );

    await runtime.run(employee, memory: memory);

    final entries = await memory.readAll();

    expect(entries, hasLength(2));
    expect(entries[0].author, MemoryAuthor.user);
    expect(entries[1].author, MemoryAuthor.employee);
    expect(entries[1].content, 'final answer');
  });

  test(
    'run() records the AssistantMessage, each ToolMessage, and the final '
    'AssistantMessage into the given memory when tool calls exist, in order',
    () async {
      final memory = ConversationMemory();
      final modelProvider = _TwoStepModelProvider()
        ..firstResponse = const ModelResponse(
          text: 'let me check',
          toolCalls: [ToolCall(id: 'call_1', name: 'search', arguments: '{}')],
        )
        ..secondResponse = const ModelResponse(text: 'final answer');
      final runtime = Runtime(
        modelProvider: modelProvider,
        requestBuilder: DefaultRuntimeRequestBuilder(),
        responseHandler: DefaultEmployeeResponseHandler(),
        toolInvoker: _SpyToolInvoker(),
      );

      await runtime.run(employee, memory: memory);

      final entries = await memory.readAll();

      // UserMessage, first AssistantMessage, ToolMessage, second
      // AssistantMessage. SystemMessage is excluded.
      expect(entries, hasLength(4));
      expect(entries[0].author, MemoryAuthor.user);
      expect(entries[1].author, MemoryAuthor.employee);
      expect(entries[1].content, 'let me check');
      expect(entries[2].author, MemoryAuthor.tool);
      expect(entries[3].author, MemoryAuthor.employee);
      expect(entries[3].content, 'final answer');
    },
  );

  test('run() does not call modelProvider.stream()', () async {
    final modelProvider = _StreamingModelProvider();
    final runtime = Runtime(
      modelProvider: modelProvider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
    );

    await runtime.run(employee);

    expect(modelProvider.streamCallCount, 0);
  });

  test('streamAndAggregate() calls modelProvider.stream() with the given '
      'request and modelConfig', () async {
    const request = ModelRequest(conversation: Conversation());
    const modelConfig = ModelConfig(model: 'gpt-4', temperature: 0.7);
    final modelProvider = _StreamingModelProvider()
      ..chunks = const [ModelResponseChunk(isFinished: true)];
    final runtime = Runtime(
      modelProvider: modelProvider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
    );

    await runtime.streamAndAggregate(request, modelConfig);

    expect(modelProvider.streamCallCount, 1);
    expect(modelProvider.capturedStreamRequest, same(request));
    expect(modelProvider.capturedStreamModelConfig, same(modelConfig));
  });

  test(
    'streamAndAggregate() returns the StreamingResponseAggregator-aggregated '
    'ModelResponse',
    () async {
      const request = ModelRequest(conversation: Conversation());
      const modelConfig = ModelConfig(model: 'gpt-4', temperature: 0.7);
      const toolCall = ToolCall(id: 'call_1', name: 'search', arguments: '{}');
      final modelProvider = _StreamingModelProvider()
        ..chunks = const [
          ModelResponseChunk(textDelta: 'Hello'),
          ModelResponseChunk(textDelta: ' world'),
          ModelResponseChunk(toolCalls: [toolCall]),
          ModelResponseChunk(isFinished: true),
        ];
      final runtime = Runtime(
        modelProvider: modelProvider,
        requestBuilder: DefaultRuntimeRequestBuilder(),
        responseHandler: DefaultEmployeeResponseHandler(),
      );

      final response = await runtime.streamAndAggregate(request, modelConfig);

      expect(response.text, 'Hello world');
      expect(response.toolCalls, [toolCall]);
    },
  );

  test('stream() delegates to modelProvider.stream() with a ModelRequest built '
      'for the given employee', () async {
    const modelConfig = ModelConfig(model: 'gpt-4', temperature: 0.7);
    const definition = ToolDefinition(
      id: 'search',
      description: 'Search the web.',
    );
    final modelProvider = _StreamingModelProvider()
      ..chunks = const [ModelResponseChunk(isFinished: true)];
    final runtime = Runtime(
      modelProvider: modelProvider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
      toolRegistry: const ToolRegistry(definitions: {'search': definition}),
    );

    await runtime.stream(employee, modelConfig);

    expect(modelProvider.streamCallCount, 1);
    expect(modelProvider.capturedStreamModelConfig, same(modelConfig));
    expect(modelProvider.capturedStreamRequest!.tools, [definition]);
    expect(
      (modelProvider.capturedStreamRequest!.conversation.messages[0]
              as SystemMessage)
          .content,
      contains('Marketing Employee'),
    );
  });

  test('stream() returns a Runtime-owned StreamingResponse, not the '
      'ModelProvider instance directly', () async {
    const modelConfig = ModelConfig(model: 'gpt-4', temperature: 0.7);
    final modelProvider = _StreamingModelProvider()
      ..chunks = const [ModelResponseChunk(isFinished: true)];
    final runtime = Runtime(
      modelProvider: modelProvider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
    );

    final result = await runtime.stream(employee, modelConfig);

    expect(result, isNot(same(modelProvider.returnedStreamingResponse)));
  });

  test('stream() forwards every chunk produced by the provider unchanged, '
      'in order, without aggregating', () async {
    const modelConfig = ModelConfig(model: 'gpt-4', temperature: 0.7);
    const toolCall = ToolCall(id: 'call_1', name: 'search', arguments: '{}');
    const providerChunks = [
      ModelResponseChunk(textDelta: 'Hello'),
      ModelResponseChunk(textDelta: ' world'),
      ModelResponseChunk(toolCalls: [toolCall]),
      ModelResponseChunk(isFinished: true),
    ];
    final modelProvider = _StreamingModelProvider()..chunks = providerChunks;
    final runtime = Runtime(
      modelProvider: modelProvider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
    );

    final result = await runtime.stream(employee, modelConfig);
    final forwardedChunks = await result.stream.toList();

    expect(forwardedChunks, hasLength(providerChunks.length));

    for (var i = 0; i < providerChunks.length; i++) {
      expect(forwardedChunks[i].textDelta, providerChunks[i].textDelta);
      expect(forwardedChunks[i].toolCalls, providerChunks[i].toolCalls);
      expect(forwardedChunks[i].isFinished, providerChunks[i].isFinished);
    }
  });

  test('stream() does not execute any tool calls until the returned stream is '
      'consumed', () async {
    const modelConfig = ModelConfig(model: 'gpt-4', temperature: 0.7);
    final toolInvoker = _SpyToolInvoker();
    final modelProvider = _StreamingModelProvider()
      ..chunks = const [
        ModelResponseChunk(
          toolCalls: [ToolCall(id: 'call_1', name: 'search', arguments: '{}')],
        ),
        ModelResponseChunk(isFinished: true),
      ];
    final runtime = Runtime(
      modelProvider: modelProvider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
      toolInvoker: toolInvoker,
    );

    await runtime.stream(employee, modelConfig);

    expect(toolInvoker.invokedToolCalls, isEmpty);
  });

  test('stream() executes a completed ToolCall exactly once while the '
      'returned stream is consumed, forwarding chunks unchanged', () async {
    const modelConfig = ModelConfig(model: 'gpt-4', temperature: 0.7);
    const toolCall = ToolCall(
      id: 'call_1',
      name: 'search',
      arguments: '{"q":"hi"}',
    );
    final toolInvoker = _SpyToolInvoker();
    const providerChunks = [
      ModelResponseChunk(toolCalls: [toolCall]),
      ModelResponseChunk(isFinished: true),
    ];
    final modelProvider = _StreamingModelProvider()..chunks = providerChunks;
    final runtime = Runtime(
      modelProvider: modelProvider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
      toolInvoker: toolInvoker,
    );

    final result = await runtime.stream(employee, modelConfig);
    final forwardedChunks = await result.stream.toList();

    expect(toolInvoker.invokedToolCalls, hasLength(1));
    expect(toolInvoker.invokedToolCalls[0].id, 'call_1');
    expect(toolInvoker.invokedToolCalls[0].arguments, '{"q":"hi"}');
    expect(forwardedChunks, hasLength(providerChunks.length));

    for (var i = 0; i < providerChunks.length; i++) {
      expect(forwardedChunks[i].isFinished, providerChunks[i].isFinished);
    }
  });

  test(
    'stream() executes each of multiple completed ToolCalls exactly once',
    () async {
      const modelConfig = ModelConfig(model: 'gpt-4', temperature: 0.7);
      final toolInvoker = _SpyToolInvoker();
      final modelProvider = _StreamingModelProvider()
        ..chunks = const [
          ModelResponseChunk(
            toolCalls: [
              ToolCall(id: 'call_1', name: 'search', arguments: '{}'),
            ],
          ),
          ModelResponseChunk(
            toolCalls: [
              ToolCall(id: 'call_2', name: 'calculator', arguments: '{}'),
            ],
          ),
          ModelResponseChunk(isFinished: true),
        ];
      final runtime = Runtime(
        modelProvider: modelProvider,
        requestBuilder: DefaultRuntimeRequestBuilder(),
        responseHandler: DefaultEmployeeResponseHandler(),
        toolInvoker: toolInvoker,
      );

      final result = await runtime.stream(employee, modelConfig);
      await result.stream.toList();

      expect(toolInvoker.invokedToolCalls.map((c) => c.id), [
        'call_1',
        'call_2',
      ]);
    },
  );

  test(
    'stream() records each executed ToolCall as an AssistantMessage/'
    'ToolMessage pair in the internal Conversation, in execution order',
    () async {
      const modelConfig = ModelConfig(model: 'gpt-4', temperature: 0.7);
      final toolInvoker = _SpyToolInvoker();
      final modelProvider = _StreamingModelProvider()
        ..chunks = const [
          ModelResponseChunk(
            toolCalls: [
              ToolCall(id: 'call_1', name: 'search', arguments: '{}'),
            ],
          ),
          ModelResponseChunk(
            toolCalls: [
              ToolCall(id: 'call_2', name: 'calculator', arguments: '{}'),
            ],
          ),
          ModelResponseChunk(isFinished: true),
        ];
      final runtime = Runtime(
        modelProvider: modelProvider,
        requestBuilder: DefaultRuntimeRequestBuilder(),
        responseHandler: DefaultEmployeeResponseHandler(),
        toolInvoker: toolInvoker,
      );

      final result = await runtime.stream(employee, modelConfig);
      await result.stream.toList();

      // Reaches the Runtime-internal conversation getter dynamically: the
      // concrete StreamingResponse type is private (not part of the public
      // API), but its public-named `conversation` member is still
      // reachable via dynamic dispatch, which is how this internal-only
      // state is verified without exposing it through any public API.
      final conversation = await (result as dynamic).conversation;
      final originalLength = DefaultRuntimeRequestBuilder()
          .build(employee)
          .conversation
          .messages
          .length;
      final appended = conversation.messages.sublist(originalLength);

      expect(appended, hasLength(4));

      expect(appended[0], isA<AssistantMessage>());
      expect((appended[0] as AssistantMessage).toolCalls.map((c) => c.id), [
        'call_1',
      ]);
      expect(appended[1], isA<ToolMessage>());
      expect((appended[1] as ToolMessage).toolCallId, 'call_1');

      expect(appended[2], isA<AssistantMessage>());
      expect((appended[2] as AssistantMessage).toolCalls.map((c) => c.id), [
        'call_2',
      ]);
      expect(appended[3], isA<ToolMessage>());
      expect((appended[3] as ToolMessage).toolCallId, 'call_2');
    },
  );

  test('stream() does not mutate the Conversation after streaming begins: the '
      'request sent to the provider contains exactly the messages '
      'RuntimeRequestBuilder produced', () async {
    const modelConfig = ModelConfig(model: 'gpt-4', temperature: 0.7);
    final modelProvider = _StreamingModelProvider()
      ..chunks = const [
        ModelResponseChunk(textDelta: 'Hello'),
        ModelResponseChunk(isFinished: true),
      ];
    final runtime = Runtime(
      modelProvider: modelProvider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
    );
    final expectedRequest = DefaultRuntimeRequestBuilder().build(employee);

    await runtime.stream(employee, modelConfig);

    expect(
      modelProvider.capturedStreamRequest!.conversation.messages,
      hasLength(expectedRequest.conversation.messages.length),
    );
  });

  test(
    'stream() makes no follow-up request when no ToolCalls occurred',
    () async {
      const modelConfig = ModelConfig(model: 'gpt-4', temperature: 0.7);
      final modelProvider = _StreamingModelProvider()
        ..chunks = const [
          ModelResponseChunk(textDelta: 'Hello'),
          ModelResponseChunk(isFinished: true),
        ];
      final runtime = Runtime(
        modelProvider: modelProvider,
        requestBuilder: DefaultRuntimeRequestBuilder(),
        responseHandler: DefaultEmployeeResponseHandler(),
      );

      final result = await runtime.stream(employee, modelConfig);
      await result.stream.toList();

      expect(modelProvider.streamCallCount, 1);
    },
  );

  test('stream() makes exactly one follow-up request when a ToolCall '
      'executed, using the updated Conversation, and forwards both provider '
      'streams as one continuous stream', () async {
    const modelConfig = ModelConfig(model: 'gpt-4', temperature: 0.7);
    final toolInvoker = _SpyToolInvoker();
    final modelProvider = _StreamingModelProvider()
      ..chunks = const [
        ModelResponseChunk(
          toolCalls: [ToolCall(id: 'call_1', name: 'search', arguments: '{}')],
        ),
        ModelResponseChunk(isFinished: true),
      ]
      ..secondChunks = const [
        ModelResponseChunk(textDelta: 'final answer'),
        ModelResponseChunk(isFinished: true),
      ];
    final runtime = Runtime(
      modelProvider: modelProvider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
      toolInvoker: toolInvoker,
    );

    final result = await runtime.stream(employee, modelConfig);
    final forwardedChunks = await result.stream.toList();

    expect(modelProvider.streamCallCount, 2);

    // One continuous stream: the first round's 2 chunks followed by the
    // second round's 2 chunks, in order.
    expect(forwardedChunks, hasLength(4));
    expect(forwardedChunks[0].toolCalls, hasLength(1));
    expect(forwardedChunks[1].isFinished, isTrue);
    expect(forwardedChunks[2].textDelta, 'final answer');
    expect(forwardedChunks[3].isFinished, isTrue);

    // The follow-up request is built from the updated Conversation: the
    // original messages plus the AssistantMessage/ToolMessage pair
    // recorded for the executed ToolCall.
    final firstRequest = modelProvider.capturedStreamRequests[0];
    final secondRequest = modelProvider.capturedStreamRequests[1];
    final originalLength = firstRequest.conversation.messages.length;
    final appended = secondRequest.conversation.messages.sublist(
      originalLength,
    );

    expect(
      secondRequest.conversation.messages.sublist(0, originalLength),
      orderedEquals(firstRequest.conversation.messages),
    );
    expect(appended, hasLength(2));
    expect(appended[0], isA<AssistantMessage>());
    expect((appended[0] as AssistantMessage).toolCalls.map((c) => c.id), [
      'call_1',
    ]);
    expect(appended[1], isA<ToolMessage>());
    expect((appended[1] as ToolMessage).toolCallId, 'call_1');
  });
}
