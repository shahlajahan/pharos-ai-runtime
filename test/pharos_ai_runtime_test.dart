import 'dart:async';

import 'package:pharos_ai_runtime/core/agent.dart';
import 'package:pharos_ai_runtime/core/config.dart';
import 'package:pharos_ai_runtime/core/context.dart';
import 'package:pharos_ai_runtime/core/logger.dart';
import 'package:pharos_ai_runtime/core/result.dart';
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
}
