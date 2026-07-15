import 'dart:io';

import 'package:pharos_ai_runtime/hq/employee_discovery.dart';
import 'package:pharos_ai_runtime/hq/employee_loader.dart';
import 'package:pharos_ai_runtime/hq/hq_bootstrap.dart';
import 'package:pharos_ai_runtime/hq/hq_validator.dart';
import 'package:pharos_ai_runtime/hq/local_hq_source.dart';
import 'package:pharos_ai_runtime/runtime/runtime.dart';
import 'package:test/test.dart';

HQBootstrap _realBootstrap() => HQBootstrap(
  validator: HQValidator(),
  discovery: EmployeeDiscovery(),
  loader: EmployeeLoader(),
);

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('runtime_cli_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test(
    'Runtime executes the Agent when --hq points to a valid HQ',
    () async {
      Directory('${tempDir.path}/employees').createSync();
      Directory('${tempDir.path}/knowledge').createSync();

      final runtime = Runtime(bootstrap: _realBootstrap());

      final result = await runtime.run(
        ['marketing'],
        source: LocalHQSource(tempDir.path),
      );

      expect(result, isNotNull);
      expect(result!.success, isTrue);
    },
  );

  test(
    'Runtime returns Result.failure without executing the Agent '
    'when --hq points to an invalid HQ',
    () async {
      final runtime = Runtime(bootstrap: _realBootstrap());

      final result = await runtime.run(
        ['marketing'],
        source: LocalHQSource('${tempDir.path}/does-not-exist'),
      );

      expect(result, isNotNull);
      expect(result!.success, isFalse);
    },
  );

  test('Runtime behaves normally when --hq is not provided', () async {
    final runtime = Runtime();

    final result = await runtime.run(['marketing']);

    expect(result, isNotNull);
    expect(result!.success, isTrue);
  });
}
