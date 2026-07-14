import 'dart:async';

import 'package:pharos_ai_runtime/core/agent.dart';
import 'package:pharos_ai_runtime/core/config.dart';
import 'package:pharos_ai_runtime/core/context.dart';
import 'package:pharos_ai_runtime/core/job.dart';
import 'package:pharos_ai_runtime/core/logger.dart';
import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/runtime/agent_registry.dart';
import 'package:pharos_ai_runtime/runtime/execution_pipeline.dart';
import 'package:pharos_ai_runtime/runtime/execution_step.dart';
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
  test('Config exposes default values', () {
    const config = Config();

    expect(config.appName, 'Pharos AI Runtime');
    expect(config.version, '0.1.0');
    expect(config.environment, 'development');
    expect(config.logLevel, 'info');
  });

  test('Config accepts overrides', () {
    const config = Config(
      appName: 'Custom App',
      version: '2.0.0',
      environment: 'production',
      logLevel: 'warn',
    );

    expect(config.appName, 'Custom App');
    expect(config.version, '2.0.0');
    expect(config.environment, 'production');
    expect(config.logLevel, 'warn');
  });

  test('Logger formats messages with level prefix and no extras', () {
    const logger = Logger();
    final output = <String>[];

    runZoned(
      () {
        logger.debug('debug message');
        logger.info('info message');
        logger.warning('warning message');
        logger.error('error message');
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) => output.add(line),
      ),
    );

    expect(output, [
      '[DEBUG] debug message',
      '[INFO] info message',
      '[WARNING] warning message',
      '[ERROR] error message',
    ]);
  });

  test('Result.success carries success flag and message', () {
    final result = Result.success('it worked');

    expect(result.success, isTrue);
    expect(result.message, 'it worked');
  });

  test('Result.failure carries success flag and message', () {
    final result = Result.failure('it failed');

    expect(result.success, isFalse);
    expect(result.message, 'it failed');
  });

  test('Runtime resolves the marketing agent and returns its Result', () async {
    final runtime = Runtime();

    final result = await runtime.run(['marketing']);

    expect(result, isNotNull);
    expect(result!.success, isTrue);
  });

  test(
    'Runtime catches agent exceptions and returns Result.failure',
    () async {
      final runtime = Runtime(registry: _ThrowingAgentRegistry());

      final result = await runtime.run(['throwing']);

      expect(result, isNotNull);
      expect(result!.success, isFalse);
      expect(result.message, contains('boom'));
    },
  );

  test('Job stores id, agentId, and createdAt', () {
    final createdAt = DateTime(2024, 1, 1);
    final job = Job(id: 'job-1', agentId: 'marketing', createdAt: createdAt);

    expect(job.id, 'job-1');
    expect(job.agentId, 'marketing');
    expect(job.createdAt, createdAt);
  });

  test('ExecutionContext exposes its Job', () {
    final job = Job(
      id: 'job-1',
      agentId: 'marketing',
      createdAt: DateTime(2024, 1, 1),
    );
    final context = ExecutionContext(
      sessionId: 'session-1',
      startedAt: DateTime(2024, 1, 1),
      environment: 'test',
      job: job,
    );

    expect(context.job, same(job));
  });

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

  test('ExecutionStep stores id and name', () {
    const step = ExecutionStep(id: 'step-1', name: 'agent-execution');

    expect(step.id, 'step-1');
    expect(step.name, 'agent-execution');
  });

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
