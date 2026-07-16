import 'package:pharos_ai_runtime/core/agent.dart';
import 'package:pharos_ai_runtime/core/context.dart';
import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/employees/employee_definition.dart';
import 'package:pharos_ai_runtime/employees/employee_repository.dart';
import 'package:pharos_ai_runtime/employees/markdown_employee_parser.dart';
import 'package:pharos_ai_runtime/hq/employee_discovery.dart';
import 'package:pharos_ai_runtime/hq/employee_loader.dart';
import 'package:pharos_ai_runtime/hq/hq_boot_result.dart';
import 'package:pharos_ai_runtime/hq/hq_bootstrap.dart';
import 'package:pharos_ai_runtime/hq/hq_source.dart';
import 'package:pharos_ai_runtime/hq/hq_validator.dart';
import 'package:pharos_ai_runtime/knowledge/knowledge_repository.dart';
import 'package:pharos_ai_runtime/knowledge/markdown_knowledge_parser.dart';
import 'package:pharos_ai_runtime/models/mock_model_provider.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/models/model_response.dart';
import 'package:pharos_ai_runtime/prompts/markdown_prompt_parser.dart';
import 'package:pharos_ai_runtime/prompts/prompt_repository.dart';
import 'package:pharos_ai_runtime/runtime/agent_registry.dart';
import 'package:pharos_ai_runtime/runtime/default_employee_response_handler.dart';
import 'package:pharos_ai_runtime/runtime/default_runtime_request_builder.dart';
import 'package:pharos_ai_runtime/runtime/employee_factory.dart';
import 'package:pharos_ai_runtime/runtime/employee_runtime.dart';
import 'package:pharos_ai_runtime/runtime/runtime.dart';
import 'package:pharos_ai_runtime/runtime/runtime_request_builder.dart';
import 'package:test/test.dart';

class _PlaceholderHQSource extends HQSource {
  @override
  Future<String> rootPath() async => '/placeholder/hq';
}

class _StubHQBootstrap extends HQBootstrap {
  _StubHQBootstrap(this._employees)
    : super(
        validator: HQValidator(),
        repository: EmployeeRepository(
          discovery: EmployeeDiscovery(),
          loader: EmployeeLoader(),
          parser: MarkdownEmployeeParser(),
        ),
        employeeFactory: EmployeeFactory(
          knowledgeRepository: KnowledgeRepository(
            parser: MarkdownKnowledgeParser(),
          ),
          promptRepository: PromptRepository(parser: MarkdownPromptParser()),
        ),
      );

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

  @override
  Future<ModelResponse> generate(ModelRequest request) async {
    callCount++;
    capturedRequest = request;

    return super.generate(request);
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
}
