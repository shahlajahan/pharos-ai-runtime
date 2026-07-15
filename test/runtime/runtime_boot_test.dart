import 'package:pharos_ai_runtime/core/agent.dart';
import 'package:pharos_ai_runtime/core/context.dart';
import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/hq/employee_discovery.dart';
import 'package:pharos_ai_runtime/hq/employee_loader.dart';
import 'package:pharos_ai_runtime/hq/hq_bootstrap.dart';
import 'package:pharos_ai_runtime/hq/hq_source.dart';
import 'package:pharos_ai_runtime/hq/hq_validator.dart';
import 'package:pharos_ai_runtime/runtime/agent_registry.dart';
import 'package:pharos_ai_runtime/runtime/runtime.dart';
import 'package:test/test.dart';

class _PlaceholderHQSource extends HQSource {
  @override
  Future<String> rootPath() async => '/placeholder/hq';
}

class _SucceedingBootstrap extends HQBootstrap {
  _SucceedingBootstrap()
    : super(
        validator: HQValidator(),
        discovery: EmployeeDiscovery(),
        loader: EmployeeLoader(),
      );

  @override
  Future<Result> boot(HQSource source) async => Result.success('booted');
}

class _FailingBootstrap extends HQBootstrap {
  _FailingBootstrap()
    : super(
        validator: HQValidator(),
        discovery: EmployeeDiscovery(),
        loader: EmployeeLoader(),
      );

  @override
  Future<Result> boot(HQSource source) async => Result.failure('boot failed');
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
      registry: _SpyAgentRegistry(agent),
      bootstrap: _SucceedingBootstrap(),
      source: _PlaceholderHQSource(),
    );

    final result = await runtime.run(['spy']);

    expect(agent.executed, isTrue);
    expect(result, isNotNull);
    expect(result!.success, isTrue);
  });

  test('Runtime does not execute the Agent when bootstrap fails', () async {
    final agent = _SpyAgent();
    final runtime = Runtime(
      registry: _SpyAgentRegistry(agent),
      bootstrap: _FailingBootstrap(),
      source: _PlaceholderHQSource(),
    );

    final result = await runtime.run(['spy']);

    expect(agent.executed, isFalse);
    expect(result, isNotNull);
    expect(result!.success, isFalse);
    expect(result.message, 'boot failed');
  });

  test(
    'Runtime behaves exactly as before when no bootstrap is provided',
    () async {
      final agent = _SpyAgent();
      final runtime = Runtime(registry: _SpyAgentRegistry(agent));

      final result = await runtime.run(['spy']);

      expect(agent.executed, isTrue);
      expect(result, isNotNull);
      expect(result!.success, isTrue);
    },
  );
}
