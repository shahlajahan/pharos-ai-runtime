import 'package:pharos_ai_runtime/core/context.dart';
import 'package:pharos_ai_runtime/runtime/agent_registry.dart';

class Runtime {
  final _registry = AgentRegistry();

  Future<void> run(List<String> args) async {
    if (args.isEmpty) {
      print('Usage:');
      print('pharos marketing');
      return;
    }

    final agent = _registry.find(args.first);

    if (agent == null) {
      print('Unknown agent.');
      return;
    }

    final context = ExecutionContext(
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
      startedAt: DateTime.now(),
      environment: 'development',
    );

    await agent.run(context);
  }
}