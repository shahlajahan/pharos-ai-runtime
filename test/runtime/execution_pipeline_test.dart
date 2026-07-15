import 'dart:async';

import 'package:pharos_ai_runtime/core/agent.dart';
import 'package:pharos_ai_runtime/core/config.dart';
import 'package:pharos_ai_runtime/core/context.dart';
import 'package:pharos_ai_runtime/core/logger.dart';
import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/runtime/execution_pipeline.dart';
import 'package:test/test.dart';

class _ThrowingAgent extends Agent {
  @override
  String get id => 'throwing';

  @override
  Future<Result> run(ExecutionContext context) async {
    throw StateError('boom');
  }
}

class _CapturingAgent extends Agent {
  ExecutionContext? capturedContext;

  @override
  String get id => 'capturing';

  @override
  Future<Result> run(ExecutionContext context) async {
    capturedContext = context;
    return Result.success('captured');
  }
}

void main() {
  test(
    'ExecutionPipeline creates a Job/Context and executes the Agent',
    () async {
      const pipeline = ExecutionPipeline(
        config: Config(environment: 'test'),
        logger: Logger(),
      );
      final agent = _CapturingAgent();

      final result = await pipeline.run(agent);

      expect(result.success, isTrue);
      expect(result.message, 'captured');
      expect(agent.capturedContext, isNotNull);
      expect(agent.capturedContext!.job.agentId, 'capturing');
      expect(agent.capturedContext!.environment, 'test');
    },
  );

  test(
    'ExecutionPipeline catches agent exceptions and returns Result.failure',
    () async {
      const pipeline = ExecutionPipeline(
        config: Config(),
        logger: Logger(),
      );

      final result = await pipeline.run(_ThrowingAgent());

      expect(result.success, isFalse);
      expect(result.message, contains('boom'));
    },
  );

  test(
    'ExecutionPipeline creates and uses one ExecutionStep before invoking the Agent',
    () async {
      const pipeline = ExecutionPipeline(config: Config(), logger: Logger());
      final agent = _CapturingAgent();
      final output = <String>[];

      await runZoned(
        () => pipeline.run(agent),
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) => output.add(line),
        ),
      );

      expect(
        output.any((line) => line.contains('agent-execution')),
        isTrue,
      );
    },
  );
}
