import 'dart:io';

import 'package:pharos_ai_runtime/hq/employee_discovery.dart';
import 'package:pharos_ai_runtime/hq/employee_loader.dart';
import 'package:pharos_ai_runtime/hq/hq_bootstrap.dart';
import 'package:pharos_ai_runtime/hq/hq_source.dart';
import 'package:pharos_ai_runtime/hq/hq_validator.dart';
import 'package:pharos_ai_runtime/hq/local_hq_source.dart';
import 'package:test/test.dart';

class _EmployeeDiscoveryWithMissingEmployee extends EmployeeDiscovery {
  @override
  Future<List<String>> discover(HQSource source) async => ['ghost-employee'];
}

HQBootstrap _bootstrap({EmployeeDiscovery? discovery}) => HQBootstrap(
  validator: HQValidator(),
  discovery: discovery ?? EmployeeDiscovery(),
  loader: EmployeeLoader(),
);

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('hq_bootstrap_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('boot() returns Result.failure for an invalid HQ', () async {
    final result = await _bootstrap().boot(LocalHQSource(tempDir.path));

    expect(result.success, isFalse);
  });

  test('boot() succeeds for an empty but valid HQ', () async {
    Directory('${tempDir.path}/employees').createSync();
    Directory('${tempDir.path}/knowledge').createSync();

    final result = await _bootstrap().boot(LocalHQSource(tempDir.path));

    expect(result.success, isTrue);
  });

  test('boot() succeeds for an HQ with multiple employees', () async {
    Directory('${tempDir.path}/employees/marketing').createSync(
      recursive: true,
    );
    Directory('${tempDir.path}/employees/engineering').createSync();
    Directory('${tempDir.path}/knowledge').createSync();

    final result = await _bootstrap().boot(LocalHQSource(tempDir.path));

    expect(result.success, isTrue);
  });

  test(
    'boot() returns Result.failure when a discovered employee directory is missing',
    () async {
      Directory('${tempDir.path}/employees').createSync();
      Directory('${tempDir.path}/knowledge').createSync();

      final bootstrap = _bootstrap(
        discovery: _EmployeeDiscoveryWithMissingEmployee(),
      );

      final result = await bootstrap.boot(LocalHQSource(tempDir.path));

      expect(result.success, isFalse);
    },
  );
}
