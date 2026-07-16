import 'package:pharos_ai_runtime/core/agent.dart';
import 'package:pharos_ai_runtime/core/context.dart';
import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/employees/employee_definition.dart';
import 'package:pharos_ai_runtime/hq/hq_boot_result.dart';
import 'package:pharos_ai_runtime/hq/hq_bootstrapper.dart';
import 'package:pharos_ai_runtime/hq/hq_source.dart';
import 'package:pharos_ai_runtime/models/mock_model_provider.dart';
import 'package:pharos_ai_runtime/models/model_exception.dart';
import 'package:pharos_ai_runtime/models/model_provider.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/models/model_response.dart';
import 'package:pharos_ai_runtime/models/openai_exception.dart';
import 'package:pharos_ai_runtime/runtime/agent_registry.dart';
import 'package:pharos_ai_runtime/runtime/default_employee_response_handler.dart';
import 'package:pharos_ai_runtime/runtime/default_runtime_request_builder.dart';
import 'package:pharos_ai_runtime/runtime/employee_response_handler.dart';
import 'package:pharos_ai_runtime/runtime/employee_runtime.dart';
import 'package:pharos_ai_runtime/runtime/runtime.dart';
import 'package:pharos_ai_runtime/runtime/runtime_request_builder.dart';
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

  @override
  ModelRequest build(EmployeeRuntime employee) {
    callCount++;
    capturedEmployee = employee;

    return const ModelRequest(systemPrompt: '', userPrompt: '');
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
}
