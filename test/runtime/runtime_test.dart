import 'package:pharos_ai_runtime/core/agent.dart';
import 'package:pharos_ai_runtime/core/context.dart';
import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/employees/employee_definition.dart';
import 'package:pharos_ai_runtime/hq/hq_boot_result.dart';
import 'package:pharos_ai_runtime/hq/hq_bootstrapper.dart';
import 'package:pharos_ai_runtime/hq/hq_source.dart';
import 'package:pharos_ai_runtime/models/conversation.dart';
import 'package:pharos_ai_runtime/models/mock_model_provider.dart';
import 'package:pharos_ai_runtime/models/model_config.dart';
import 'package:pharos_ai_runtime/models/model_exception.dart';
import 'package:pharos_ai_runtime/models/model_provider.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/models/model_response.dart';
import 'package:pharos_ai_runtime/models/openai_exception.dart';
import 'package:pharos_ai_runtime/models/streaming_response.dart';
import 'package:pharos_ai_runtime/runtime/agent_registry.dart';
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

class _PlaceholderHQSource extends HQSource {
  @override
  Future<String> rootPath() async => '/placeholder/hq';
}

class _StubHQBootstrap extends HQBootstrapper {
  _StubHQBootstrap(this._employees);

  final List<EmployeeRuntime> _employees;

  @override
  Future<HQBootResult> boot(HQSource source) async =>
      HQBootResult(result: Result.success('booted'), employees: _employees);
}

class _ThrowingAgent extends Agent {
  @override
  String get id => 'throwing';

  @override
  Future<Result> run(ExecutionContext context) async {
    throw StateError('boom');
  }
}

class _ThrowingAgentRegistry extends AgentRegistry {
  @override
  Agent? find(String id) => _ThrowingAgent();
}

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

class _TrackingAgent extends Agent {
  bool executed = false;

  @override
  String get id => 'marketing';

  @override
  Future<Result> run(ExecutionContext context) async {
    executed = true;
    return Result.success('agent ran');
  }
}

class _TrackingAgentRegistry extends AgentRegistry {
  _TrackingAgentRegistry(this.agent);

  final _TrackingAgent agent;

  @override
  Agent? find(String id) => agent;
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
  int streamCallCount = 0;
  ModelRequest? capturedStreamRequest;
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
    capturedStreamModelConfig = modelConfig;

    final response = _FakeStreamingResponse(Stream.fromIterable(chunks));
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
  test('Runtime accepts a ModelProvider', () {
    final modelProvider = MockModelProvider();

    final runtime = Runtime(
      modelProvider: modelProvider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
    );

    expect(runtime.modelProvider, same(modelProvider));
  });

  test('Runtime resolves the marketing agent and returns its Result', () async {
    final runtime = Runtime(
      modelProvider: MockModelProvider(),
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
    );

    final result = await runtime.run(['marketing']);

    expect(result, isNotNull);
    expect(result!.success, isTrue);
  });

  test('Runtime catches agent exceptions and returns Result.failure', () async {
    final runtime = Runtime(
      modelProvider: MockModelProvider(),
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
      registry: _ThrowingAgentRegistry(),
    );

    final result = await runtime.run(['throwing']);

    expect(result, isNotNull);
    expect(result!.success, isFalse);
    expect(result.message, contains('boom'));
  });

  test('Runtime calls modelProvider.generate() exactly once', () async {
    final modelProvider = _SpyModelProvider();
    final runtime = Runtime(
      modelProvider: modelProvider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
    );

    await runtime.run(['marketing']);

    expect(modelProvider.callCount, 1);
  });

  test('Runtime calls modelProvider.generate() with a ModelRequest', () async {
    final modelProvider = _SpyModelProvider();
    final runtime = Runtime(
      modelProvider: modelProvider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
    );

    await runtime.run(['marketing']);

    expect(modelProvider.capturedRequest, isA<ModelRequest>());
  });

  test(
    'Runtime selects the matching EmployeeRuntime after a successful boot',
    () async {
      const employee = EmployeeRuntime(
        definition: EmployeeDefinition(
          id: 'marketing',
          name: 'Marketing Employee',
          role: 'Marketing',
        ),
        knowledge: [],
        prompts: [],
      );
      final runtime = Runtime(
        modelProvider: MockModelProvider(),
        requestBuilder: DefaultRuntimeRequestBuilder(),
        responseHandler: DefaultEmployeeResponseHandler(),
        bootstrap: _StubHQBootstrap([employee]),
      );

      final result = await runtime.run([
        'marketing',
      ], source: _PlaceholderHQSource());

      expect(result, isNotNull);
      expect(result!.success, isTrue);
    },
  );

  test('Runtime returns Result.failure when no employee matches the requested '
      'id', () async {
    final runtime = Runtime(
      modelProvider: MockModelProvider(),
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
      bootstrap: _StubHQBootstrap(const []),
    );

    final result = await runtime.run([
      'marketing',
    ], source: _PlaceholderHQSource());

    expect(result, isNotNull);
    expect(result!.success, isFalse);
    expect(result.message, contains('marketing'));
  });

  test(
    'Runtime delegates request creation to RuntimeRequestBuilder, calling '
    'build() exactly once with the selected EmployeeRuntime unchanged',
    () async {
      const employee = EmployeeRuntime(
        definition: EmployeeDefinition(
          id: 'marketing',
          name: 'Marketing Employee',
          role: 'Marketing',
        ),
        knowledge: [],
        prompts: [],
      );
      final requestBuilder = _SpyRuntimeRequestBuilder();
      final runtime = Runtime(
        modelProvider: MockModelProvider(),
        requestBuilder: requestBuilder,
        responseHandler: DefaultEmployeeResponseHandler(),
        bootstrap: _StubHQBootstrap([employee]),
      );

      await runtime.run(['marketing'], source: _PlaceholderHQSource());

      expect(requestBuilder.callCount, 1);
      expect(requestBuilder.capturedEmployee, same(employee));
    },
  );

  test(
    'Runtime does not invoke RuntimeRequestBuilder on the legacy no-HQ path',
    () async {
      final requestBuilder = _SpyRuntimeRequestBuilder();
      final runtime = Runtime(
        modelProvider: MockModelProvider(),
        requestBuilder: requestBuilder,
        responseHandler: DefaultEmployeeResponseHandler(),
      );

      await runtime.run(['marketing']);

      expect(requestBuilder.callCount, 0);
    },
  );

  test(
    'Runtime calls modelProvider.generate() exactly once on the HQ path',
    () async {
      const employee = EmployeeRuntime(
        definition: EmployeeDefinition(
          id: 'marketing',
          name: 'Marketing Employee',
          role: 'Marketing',
        ),
        knowledge: [],
        prompts: [],
      );
      final modelProvider = _SpyModelProvider();
      final runtime = Runtime(
        modelProvider: modelProvider,
        requestBuilder: DefaultRuntimeRequestBuilder(),
        responseHandler: DefaultEmployeeResponseHandler(),
        bootstrap: _StubHQBootstrap([employee]),
      );

      await runtime.run(['marketing'], source: _PlaceholderHQSource());

      expect(modelProvider.callCount, 1);
    },
  );

  test('Runtime calls EmployeeResponseHandler.handle() exactly once on the HQ '
      'path, forwarding the selected EmployeeRuntime and generated '
      'ModelResponse unchanged', () async {
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [],
      prompts: [],
    );
    final modelProvider = _SpyModelProvider();
    final responseHandler = _SpyEmployeeResponseHandler();
    final runtime = Runtime(
      modelProvider: modelProvider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: responseHandler,
      bootstrap: _StubHQBootstrap([employee]),
    );

    await runtime.run(['marketing'], source: _PlaceholderHQSource());

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
      const employee = EmployeeRuntime(
        definition: EmployeeDefinition(
          id: 'marketing',
          name: 'Marketing Employee',
          role: 'Marketing',
        ),
        knowledge: [],
        prompts: [],
      );
      final responseHandler = _SpyEmployeeResponseHandler()
        ..result = Result.failure('handler failure');
      final runtime = Runtime(
        modelProvider: MockModelProvider(),
        requestBuilder: DefaultRuntimeRequestBuilder(),
        responseHandler: responseHandler,
        bootstrap: _StubHQBootstrap([employee]),
      );

      final result = await runtime.run([
        'marketing',
      ], source: _PlaceholderHQSource());

      expect(result, same(responseHandler.result));
    },
  );

  test('Runtime does not execute the Agent pipeline on the HQ '
      'response-handler path', () async {
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [],
      prompts: [],
    );
    final agent = _TrackingAgent();
    final runtime = Runtime(
      modelProvider: MockModelProvider(),
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
      registry: _TrackingAgentRegistry(agent),
      bootstrap: _StubHQBootstrap([employee]),
    );

    await runtime.run(['marketing'], source: _PlaceholderHQSource());

    expect(agent.executed, isFalse);
  });

  test('Runtime does not invoke EmployeeResponseHandler on the legacy no-HQ '
      'path', () async {
    final responseHandler = _SpyEmployeeResponseHandler();
    final runtime = Runtime(
      modelProvider: MockModelProvider(),
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: responseHandler,
    );

    await runtime.run(['marketing']);

    expect(responseHandler.callCount, 0);
  });

  test('Runtime still returns the handler Result when the ModelProvider '
      'succeeds on the HQ path', () async {
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [],
      prompts: [],
    );
    final runtime = Runtime(
      modelProvider: MockModelProvider(),
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
      bootstrap: _StubHQBootstrap([employee]),
    );

    final result = await runtime.run([
      'marketing',
    ], source: _PlaceholderHQSource());

    expect(result, isNotNull);
    expect(result!.success, isTrue);
  });

  test('Runtime converts OpenAIException into Result.failure(message) on '
      'the HQ path', () async {
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [],
      prompts: [],
    );
    final runtime = Runtime(
      modelProvider: _OpenAIExceptionModelProvider(),
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
      bootstrap: _StubHQBootstrap([employee]),
    );

    final result = await runtime.run([
      'marketing',
    ], source: _PlaceholderHQSource());

    expect(result, isNotNull);
    expect(result!.success, isFalse);
    expect(result.message, 'rate limit exceeded');
  });

  test('Runtime converts any ModelException (not just OpenAIException) into '
      'Result.failure(message) on the HQ path', () async {
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [],
      prompts: [],
    );
    final runtime = Runtime(
      modelProvider: _CustomModelExceptionModelProvider(),
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
      bootstrap: _StubHQBootstrap([employee]),
    );

    final result = await runtime.run([
      'marketing',
    ], source: _PlaceholderHQSource());

    expect(result, isNotNull);
    expect(result!.success, isFalse);
    expect(result.message, 'custom model failure');
  });

  test('Runtime lets StateError propagate uncaught on the HQ path', () async {
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [],
      prompts: [],
    );
    final runtime = Runtime(
      modelProvider: _StateErrorModelProvider(),
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
      bootstrap: _StubHQBootstrap([employee]),
    );

    expect(
      () => runtime.run(['marketing'], source: _PlaceholderHQSource()),
      throwsA(isA<StateError>()),
    );
  });

  test(
    'Runtime lets FormatException propagate uncaught on the HQ path',
    () async {
      const employee = EmployeeRuntime(
        definition: EmployeeDefinition(
          id: 'marketing',
          name: 'Marketing Employee',
          role: 'Marketing',
        ),
        knowledge: [],
        prompts: [],
      );
      final runtime = Runtime(
        modelProvider: _FormatExceptionModelProvider(),
        requestBuilder: DefaultRuntimeRequestBuilder(),
        responseHandler: DefaultEmployeeResponseHandler(),
        bootstrap: _StubHQBootstrap([employee]),
      );

      expect(
        () => runtime.run(['marketing'], source: _PlaceholderHQSource()),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test(
    'Runtime accepts a custom ToolRegistry without changing behavior',
    () async {
      final runtime = Runtime(
        modelProvider: MockModelProvider(),
        requestBuilder: DefaultRuntimeRequestBuilder(),
        responseHandler: DefaultEmployeeResponseHandler(),
        toolRegistry: ToolRegistry(tools: {'noop': _NoopTool()}),
      );

      final result = await runtime.run(['marketing']);

      expect(result, isNotNull);
      expect(result!.success, isTrue);
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
      const employee = EmployeeRuntime(
        definition: EmployeeDefinition(
          id: 'marketing',
          name: 'Marketing Employee',
          role: 'Marketing',
        ),
        knowledge: [],
        prompts: [],
      );
      const definition = ToolDefinition(
        id: 'search',
        description: 'Search the web.',
      );
      final requestBuilder = _SpyRuntimeRequestBuilder();
      final runtime = Runtime(
        modelProvider: MockModelProvider(),
        requestBuilder: requestBuilder,
        responseHandler: DefaultEmployeeResponseHandler(),
        bootstrap: _StubHQBootstrap([employee]),
        toolRegistry: const ToolRegistry(definitions: {'search': definition}),
      );

      await runtime.run(['marketing'], source: _PlaceholderHQSource());

      expect(requestBuilder.capturedTools, [definition]);
    },
  );

  test(
    'Runtime forwards an empty tool list when no ToolRegistry is provided',
    () async {
      const employee = EmployeeRuntime(
        definition: EmployeeDefinition(
          id: 'marketing',
          name: 'Marketing Employee',
          role: 'Marketing',
        ),
        knowledge: [],
        prompts: [],
      );
      final requestBuilder = _SpyRuntimeRequestBuilder();
      final runtime = Runtime(
        modelProvider: MockModelProvider(),
        requestBuilder: requestBuilder,
        responseHandler: DefaultEmployeeResponseHandler(),
        bootstrap: _StubHQBootstrap([employee]),
      );

      await runtime.run(['marketing'], source: _PlaceholderHQSource());

      expect(requestBuilder.capturedTools, isEmpty);
    },
  );

  test(
    'Runtime never invokes ToolInvoker when response.toolCalls is empty',
    () async {
      const employee = EmployeeRuntime(
        definition: EmployeeDefinition(
          id: 'marketing',
          name: 'Marketing Employee',
          role: 'Marketing',
        ),
        knowledge: [],
        prompts: [],
      );
      final toolInvoker = _SpyToolInvoker();
      final runtime = Runtime(
        modelProvider: _ConfigurableModelProvider(),
        requestBuilder: DefaultRuntimeRequestBuilder(),
        responseHandler: DefaultEmployeeResponseHandler(),
        bootstrap: _StubHQBootstrap([employee]),
        toolInvoker: toolInvoker,
      );

      await runtime.run(['marketing'], source: _PlaceholderHQSource());

      expect(toolInvoker.invokedToolCalls, isEmpty);
    },
  );

  test('Runtime executes a single tool call once', () async {
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [],
      prompts: [],
    );
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
      bootstrap: _StubHQBootstrap([employee]),
      toolInvoker: toolInvoker,
    );

    await runtime.run(['marketing'], source: _PlaceholderHQSource());

    expect(toolInvoker.invokedToolCalls.map((call) => call.name), ['search']);
  });

  test('Runtime executes multiple tool calls sequentially, in order', () async {
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [],
      prompts: [],
    );
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
      bootstrap: _StubHQBootstrap([employee]),
      toolInvoker: toolInvoker,
    );

    await runtime.run(['marketing'], source: _PlaceholderHQSource());

    expect(toolInvoker.invokedToolCalls.map((call) => call.name), [
      'search',
      'calculator',
    ]);
  });

  test(
    'Runtime forwards the original ToolCall unchanged into ToolInvoker',
    () async {
      const employee = EmployeeRuntime(
        definition: EmployeeDefinition(
          id: 'marketing',
          name: 'Marketing Employee',
          role: 'Marketing',
        ),
        knowledge: [],
        prompts: [],
      );
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
        bootstrap: _StubHQBootstrap([employee]),
        toolInvoker: toolInvoker,
      );

      await runtime.run(['marketing'], source: _PlaceholderHQSource());

      expect(toolInvoker.invokedToolCalls, [same(toolCall)]);
    },
  );

  test('Runtime still returns the response-handler Result when tool calls '
      'exist', () async {
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [],
      prompts: [],
    );
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
      bootstrap: _StubHQBootstrap([employee]),
      toolInvoker: _SpyToolInvoker(),
    );

    final result = await runtime.run([
      'marketing',
    ], source: _PlaceholderHQSource());

    expect(result, same(responseHandler.result));
  });

  test('Runtime does not crash when tool execution fails, and still returns '
      'the original Result, exactly as ToolInvoker already defines', () async {
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [],
      prompts: [],
    );
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
      bootstrap: _StubHQBootstrap([employee]),
      toolInvoker: ToolInvoker(registry: const ToolRegistry()),
    );

    final result = await runtime.run([
      'marketing',
    ], source: _PlaceholderHQSource());

    expect(result, isNotNull);
    expect(result!.success, isTrue);
  });

  test('Runtime still invokes every tool call, and still returns the '
      'response-handler Result, even when tool executions fail', () async {
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [],
      prompts: [],
    );
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
      bootstrap: _StubHQBootstrap([employee]),
      toolInvoker: toolInvoker,
    );

    final result = await runtime.run([
      'marketing',
    ], source: _PlaceholderHQSource());

    expect(toolInvoker.invokedToolCalls.map((call) => call.name), [
      'search',
      'calculator',
    ]);
    expect(result, same(responseHandler.result));
  });

  test('Runtime calls modelProvider.generate() exactly once when no tool '
      'calls exist', () async {
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [],
      prompts: [],
    );
    final modelProvider = _TwoStepModelProvider()
      ..firstResponse = const ModelResponse(text: 'ok');
    final runtime = Runtime(
      modelProvider: modelProvider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
      bootstrap: _StubHQBootstrap([employee]),
    );

    await runtime.run(['marketing'], source: _PlaceholderHQSource());

    expect(modelProvider.callCount, 1);
  });

  test('Runtime calls modelProvider.generate() exactly twice when tool '
      'calls exist', () async {
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [],
      prompts: [],
    );
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
      bootstrap: _StubHQBootstrap([employee]),
    );

    await runtime.run(['marketing'], source: _PlaceholderHQSource());

    expect(modelProvider.callCount, 2);
  });

  test('Runtime sends every ToolOutput in the second request, preserving '
      'toolCallId and toolName', () async {
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [],
      prompts: [],
    );
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
      bootstrap: _StubHQBootstrap([employee]),
    );

    await runtime.run(['marketing'], source: _PlaceholderHQSource());

    final secondRequest = modelProvider.capturedRequests[1];
    expect(secondRequest.toolOutputs, hasLength(2));
    expect(secondRequest.toolOutputs[0].toolCallId, 'call_1');
    expect(secondRequest.toolOutputs[0].toolName, 'search');
    expect(secondRequest.toolOutputs[1].toolCallId, 'call_2');
    expect(secondRequest.toolOutputs[1].toolName, 'calculator');
  });

  test('Runtime passes the second ModelResponse into EmployeeResponseHandler '
      'when tool calls were executed', () async {
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [],
      prompts: [],
    );
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
      bootstrap: _StubHQBootstrap([employee]),
    );

    await runtime.run(['marketing'], source: _PlaceholderHQSource());

    expect(responseHandler.capturedResponse, same(secondResponse));
  });

  test('Runtime appends an AssistantMessage with the response content and '
      'toolCalls after tool execution', () async {
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [],
      prompts: [],
    );
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
      bootstrap: _StubHQBootstrap([employee]),
    );

    await runtime.run(['marketing'], source: _PlaceholderHQSource());

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
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [],
      prompts: [],
    );
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
      bootstrap: _StubHQBootstrap([employee]),
      toolInvoker: toolInvoker,
    );

    await runtime.run(['marketing'], source: _PlaceholderHQSource());

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
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [],
      prompts: [],
    );
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
      bootstrap: _StubHQBootstrap([employee]),
    );

    await runtime.run(['marketing'], source: _PlaceholderHQSource());

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
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [],
      prompts: [],
    );
    final modelProvider = _TwoStepModelProvider()
      ..firstResponse = const ModelResponse(text: 'ok');
    final runtime = Runtime(
      modelProvider: modelProvider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
      bootstrap: _StubHQBootstrap([employee]),
    );

    await runtime.run(['marketing'], source: _PlaceholderHQSource());

    expect(modelProvider.capturedRequests, hasLength(1));
  });

  test('run() does not call modelProvider.stream() on the existing '
      'synchronous path', () async {
    final modelProvider = _StreamingModelProvider();
    final runtime = Runtime(
      modelProvider: modelProvider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
    );

    await runtime.run(['marketing']);

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

  test(
    'stream() resolves the employee via bootstrap and delegates to '
    'modelProvider.stream() with a ModelRequest built for that employee',
    () async {
      const employee = EmployeeRuntime(
        definition: EmployeeDefinition(
          id: 'marketing',
          name: 'Marketing Employee',
          role: 'Marketing',
        ),
        knowledge: [],
        prompts: [],
      );
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
        bootstrap: _StubHQBootstrap([employee]),
        toolRegistry: const ToolRegistry(definitions: {'search': definition}),
      );

      await runtime.stream(
        ['marketing'],
        modelConfig,
        source: _PlaceholderHQSource(),
      );

      expect(modelProvider.streamCallCount, 1);
      expect(modelProvider.capturedStreamModelConfig, same(modelConfig));
      expect(modelProvider.capturedStreamRequest!.tools, [definition]);
      expect(
        (modelProvider.capturedStreamRequest!.conversation.messages[0]
                as SystemMessage)
            .content,
        contains('Marketing Employee'),
      );
    },
  );

  test('stream() returns a Runtime-owned StreamingResponse, not the '
      'ModelProvider instance directly', () async {
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [],
      prompts: [],
    );
    const modelConfig = ModelConfig(model: 'gpt-4', temperature: 0.7);
    final modelProvider = _StreamingModelProvider()
      ..chunks = const [ModelResponseChunk(isFinished: true)];
    final runtime = Runtime(
      modelProvider: modelProvider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
      bootstrap: _StubHQBootstrap([employee]),
    );

    final result = await runtime.stream(
      ['marketing'],
      modelConfig,
      source: _PlaceholderHQSource(),
    );

    expect(result, isNotNull);
    expect(result, isNot(same(modelProvider.returnedStreamingResponse)));
  });

  test('stream() forwards every chunk produced by the provider unchanged, '
      'in order, without aggregating', () async {
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [],
      prompts: [],
    );
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
      bootstrap: _StubHQBootstrap([employee]),
    );

    final result = await runtime.stream(
      ['marketing'],
      modelConfig,
      source: _PlaceholderHQSource(),
    );
    final forwardedChunks = await result!.stream.toList();

    expect(forwardedChunks, hasLength(providerChunks.length));

    for (var i = 0; i < providerChunks.length; i++) {
      expect(forwardedChunks[i].textDelta, providerChunks[i].textDelta);
      expect(forwardedChunks[i].toolCalls, providerChunks[i].toolCalls);
      expect(forwardedChunks[i].isFinished, providerChunks[i].isFinished);
    }
  });

  test('stream() does not execute any tool calls until the returned stream is '
      'consumed', () async {
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [],
      prompts: [],
    );
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
      bootstrap: _StubHQBootstrap([employee]),
      toolInvoker: toolInvoker,
    );

    await runtime.stream(
      ['marketing'],
      modelConfig,
      source: _PlaceholderHQSource(),
    );

    expect(toolInvoker.invokedToolCalls, isEmpty);
  });

  test('stream() executes a completed ToolCall exactly once while the '
      'returned stream is consumed, forwarding chunks unchanged', () async {
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [],
      prompts: [],
    );
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
      bootstrap: _StubHQBootstrap([employee]),
      toolInvoker: toolInvoker,
    );

    final result = await runtime.stream(
      ['marketing'],
      modelConfig,
      source: _PlaceholderHQSource(),
    );
    final forwardedChunks = await result!.stream.toList();

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
      const employee = EmployeeRuntime(
        definition: EmployeeDefinition(
          id: 'marketing',
          name: 'Marketing Employee',
          role: 'Marketing',
        ),
        knowledge: [],
        prompts: [],
      );
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
        bootstrap: _StubHQBootstrap([employee]),
        toolInvoker: toolInvoker,
      );

      final result = await runtime.stream(
        ['marketing'],
        modelConfig,
        source: _PlaceholderHQSource(),
      );
      await result!.stream.toList();

      expect(toolInvoker.invokedToolCalls.map((c) => c.id), [
        'call_1',
        'call_2',
      ]);
    },
  );

  test('stream() does not mutate the Conversation after streaming begins: the '
      'request sent to the provider contains exactly the messages '
      'RuntimeRequestBuilder produced', () async {
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [],
      prompts: [],
    );
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
      bootstrap: _StubHQBootstrap([employee]),
    );
    final expectedRequest = DefaultRuntimeRequestBuilder().build(employee);

    await runtime.stream(
      ['marketing'],
      modelConfig,
      source: _PlaceholderHQSource(),
    );

    expect(
      modelProvider.capturedStreamRequest!.conversation.messages,
      hasLength(expectedRequest.conversation.messages.length),
    );
  });

  test('stream() returns null when args is empty', () async {
    const modelConfig = ModelConfig(model: 'gpt-4', temperature: 0.7);
    final runtime = Runtime(
      modelProvider: _StreamingModelProvider(),
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
    );

    final result = await runtime.stream([], modelConfig);

    expect(result, isNull);
  });

  test(
    'stream() returns null when no employee matches the requested id',
    () async {
      const modelConfig = ModelConfig(model: 'gpt-4', temperature: 0.7);
      final runtime = Runtime(
        modelProvider: _StreamingModelProvider(),
        requestBuilder: DefaultRuntimeRequestBuilder(),
        responseHandler: DefaultEmployeeResponseHandler(),
        bootstrap: _StubHQBootstrap(const []),
      );

      final result = await runtime.stream(
        ['marketing'],
        modelConfig,
        source: _PlaceholderHQSource(),
      );

      expect(result, isNull);
    },
  );

  test(
    'stream() returns null when no bootstrap/source is configured',
    () async {
      const modelConfig = ModelConfig(model: 'gpt-4', temperature: 0.7);
      final runtime = Runtime(
        modelProvider: _StreamingModelProvider(),
        requestBuilder: DefaultRuntimeRequestBuilder(),
        responseHandler: DefaultEmployeeResponseHandler(),
      );

      final result = await runtime.stream(['marketing'], modelConfig);

      expect(result, isNull);
    },
  );
}
