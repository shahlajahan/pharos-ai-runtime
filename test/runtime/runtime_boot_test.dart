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
import 'package:pharos_ai_runtime/prompts/markdown_prompt_parser.dart';
import 'package:pharos_ai_runtime/prompts/prompt_repository.dart';
import 'package:pharos_ai_runtime/runtime/agent_registry.dart';
import 'package:pharos_ai_runtime/runtime/employee_factory.dart';
import 'package:pharos_ai_runtime/runtime/employee_runtime.dart';
import 'package:pharos_ai_runtime/runtime/runtime.dart';
import 'package:test/test.dart';

class _PlaceholderHQSource extends HQSource {
  @override
  Future<String> rootPath() async => '/placeholder/hq';
}

EmployeeRepository _realRepository() => EmployeeRepository(
  discovery: EmployeeDiscovery(),
  loader: EmployeeLoader(),
  parser: MarkdownEmployeeParser(),
);

EmployeeFactory _realEmployeeFactory() => EmployeeFactory(
  knowledgeRepository: KnowledgeRepository(parser: MarkdownKnowledgeParser()),
  promptRepository: PromptRepository(parser: MarkdownPromptParser()),
);

class _SucceedingBootstrap extends HQBootstrap {
  _SucceedingBootstrap()
    : super(
        validator: HQValidator(),
        repository: _realRepository(),
        employeeFactory: _realEmployeeFactory(),
      );

  @override
  Future<HQBootResult> boot(HQSource source) async => HQBootResult(
    result: Result.success('booted'),
    employees: const [
      EmployeeRuntime(
        definition: EmployeeDefinition(
          id: 'spy',
          name: 'Spy Employee',
          role: 'Spy',
        ),
        knowledge: [],
        prompts: [],
      ),
    ],
  );
}

class _FailingBootstrap extends HQBootstrap {
  _FailingBootstrap()
    : super(
        validator: HQValidator(),
        repository: _realRepository(),
        employeeFactory: _realEmployeeFactory(),
      );

  @override
  Future<HQBootResult> boot(HQSource source) async => HQBootResult(
    result: Result.failure('boot failed'),
    employees: const [],
  );
}

class _SpyAgent extends Agent {
  bool executed = false;

  @override
  String get id => 'spy';

  @override
  Future<Result> run(ExecutionContext context) async {
    executed = true;
    return Result.success('spy ran');
  }
}

class _SpyAgentRegistry extends AgentRegistry {
  _SpyAgentRegistry(this.agent);

  final _SpyAgent agent;

  @override
  Agent? find(String id) => agent;
}

void main() {
  test('Runtime executes the Agent when bootstrap succeeds', () async {
    final agent = _SpyAgent();
    final runtime = Runtime(
      modelProvider: MockModelProvider(),
      registry: _SpyAgentRegistry(agent),
      bootstrap: _SucceedingBootstrap(),
    );

    final result = await runtime.run(
      ['spy'],
      source: _PlaceholderHQSource(),
    );

    expect(agent.executed, isTrue);
    expect(result, isNotNull);
    expect(result!.success, isTrue);
  });

  test('Runtime does not execute the Agent when bootstrap fails', () async {
    final agent = _SpyAgent();
    final runtime = Runtime(
      modelProvider: MockModelProvider(),
      registry: _SpyAgentRegistry(agent),
      bootstrap: _FailingBootstrap(),
    );

    final result = await runtime.run(
      ['spy'],
      source: _PlaceholderHQSource(),
    );

    expect(agent.executed, isFalse);
    expect(result, isNotNull);
    expect(result!.success, isFalse);
    expect(result.message, 'boot failed');
  });

  test(
    'Runtime behaves exactly as before when no bootstrap is provided',
    () async {
      final agent = _SpyAgent();
      final runtime = Runtime(
        modelProvider: MockModelProvider(),
        registry: _SpyAgentRegistry(agent),
      );

      final result = await runtime.run(['spy']);

      expect(agent.executed, isTrue);
      expect(result, isNotNull);
      expect(result!.success, isTrue);
    },
  );
}
