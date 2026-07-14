import 'package:pharos_ai_runtime/core/context.dart';
import 'package:pharos_ai_runtime/runtime/agent_registry.dart';
import 'package:pharos_ai_runtime/core/config.dart';
import 'package:pharos_ai_runtime/core/logger.dart';
import 'package:pharos_ai_runtime/core/result.dart';

class Runtime {
  Runtime({
    Config config = const Config(),
    AgentRegistry? registry,
    Logger logger = const Logger(),
  }) : _config = config,
       _registry = registry ?? AgentRegistry(),
       _logger = logger;

  final Config _config;
  final AgentRegistry _registry;
  final Logger _logger;

  Future<Result?> run(List<String> args) async {
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

    final context = ExecutionContext(
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
      startedAt: DateTime.now(),
      environment: _config.environment,
    );

    try {
      return await agent.run(context);
    } catch (e) {
      _logger.error('Agent "${agent.id}" failed: $e');
      return Result.failure('Agent "${agent.id}" failed: $e');
    }
  }
}