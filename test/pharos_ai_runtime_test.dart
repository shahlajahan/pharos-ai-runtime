import 'dart:async';

import 'package:pharos_ai_runtime/core/config.dart';
import 'package:pharos_ai_runtime/core/logger.dart';
import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/runtime/runtime.dart';
import 'package:test/test.dart';

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
}
