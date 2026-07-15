import 'dart:io';

import 'package:pharos_ai_runtime/hq/hq_validator.dart';
import 'package:pharos_ai_runtime/hq/local_hq_source.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('hq_validator_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('validate() returns Result.success for a valid HQ', () async {
    Directory('${tempDir.path}/employees').createSync();
    Directory('${tempDir.path}/knowledge').createSync();

    final result = await HQValidator().validate(LocalHQSource(tempDir.path));

    expect(result.success, isTrue);
  });

  test(
    'validate() returns Result.failure when the root does not exist',
    () async {
      final missingPath = '${tempDir.path}/missing-root';

      final result = await HQValidator().validate(
        LocalHQSource(missingPath),
      );

      expect(result.success, isFalse);
    },
  );

  test(
    'validate() returns Result.failure when employees/ is missing',
    () async {
      Directory('${tempDir.path}/knowledge').createSync();

      final result = await HQValidator().validate(LocalHQSource(tempDir.path));

      expect(result.success, isFalse);
    },
  );

  test(
    'validate() returns Result.failure when knowledge/ is missing',
    () async {
      Directory('${tempDir.path}/employees').createSync();

      final result = await HQValidator().validate(LocalHQSource(tempDir.path));

      expect(result.success, isFalse);
    },
  );
}
