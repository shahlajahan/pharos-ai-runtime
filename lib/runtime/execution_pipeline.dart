import 'package:pharos_ai_runtime/core/agent.dart';
import 'package:pharos_ai_runtime/core/config.dart';
import 'package:pharos_ai_runtime/core/context.dart';
import 'package:pharos_ai_runtime/core/job.dart';
import 'package:pharos_ai_runtime/core/logger.dart';
import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/runtime/execution_step.dart';

class ExecutionPipeline {
  const ExecutionPipeline({required Config config, required Logger logger})
    : _config = config,
      _logger = logger;

  final Config _config;
  final Logger _logger;

  Future<Result> run(Agent agent) async {
    final job = Job(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      agentId: agent.id,
      createdAt: DateTime.now(),
    );

    final context = ExecutionContext(
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
      startedAt: DateTime.now(),
      environment: _config.environment,
      job: job,
    );

    final step = ExecutionStep(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'agent-execution',
    );
    _logger.debug('Executing step "${step.name}" (${step.id})');

    try {
      return await agent.run(context);
    } catch (e) {
      _logger.error('Agent "${agent.id}" failed: $e');
      return Result.failure('Agent "${agent.id}" failed: $e');
    }
  }
}
