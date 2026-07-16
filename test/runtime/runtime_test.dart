import 'package:pharos_ai_runtime/core/agent.dart';
import 'package:pharos_ai_runtime/core/context.dart';
import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/models/mock_model_provider.dart';
import 'package:pharos_ai_runtime/runtime/agent_registry.dart';
import 'package:pharos_ai_runtime/runtime/runtime.dart';
import 'package:test/test.dart';

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

void main() {
  test('Runtime accepts a ModelProvider', () {
    final modelProvider = MockModelProvider();

    final runtime = Runtime(modelProvider: modelProvider);

    expect(runtime.modelProvider, same(modelProvider));
  });

  test('Runtime resolves the marketing agent and returns its Result', () async {
    final runtime = Runtime(modelProvider: MockModelProvider());

    final result = await runtime.run(['marketing']);

    expect(result, isNotNull);
    expect(result!.success, isTrue);
  });

  test(
    'Runtime catches agent exceptions and returns Result.failure',
    () async {
      final runtime = Runtime(
        modelProvider: MockModelProvider(),
        registry: _ThrowingAgentRegistry(),
      );

      final result = await runtime.run(['throwing']);

      expect(result, isNotNull);
      expect(result!.success, isFalse);
      expect(result.message, contains('boom'));
    },
  );
}
