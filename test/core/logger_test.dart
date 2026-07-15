import 'dart:async';

import 'package:pharos_ai_runtime/core/logger.dart';
import 'package:test/test.dart';

void main() {
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
}
