import 'dart:io';

import 'package:pharos_ai_runtime/hq/employee_discovery.dart';
import 'package:pharos_ai_runtime/hq/local_hq_source.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('employee_discovery_test_');
    Directory('${tempDir.path}/employees').createSync();
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('discover() returns [] for an empty employees directory', () async {
    final result = await EmployeeDiscovery().discover(
      LocalHQSource(tempDir.path),
    );

    expect(result, isEmpty);
  });

  test('discover() ignores files inside employees/', () async {
    File('${tempDir.path}/employees/notes.txt').createSync();
    Directory('${tempDir.path}/employees/marketing').createSync();

    final result = await EmployeeDiscovery().discover(
      LocalHQSource(tempDir.path),
    );

    expect(result, ['marketing']);
  });

  test('discover() ignores hidden directories', () async {
    Directory('${tempDir.path}/employees/.git').createSync();
    Directory('${tempDir.path}/employees/marketing').createSync();

    final result = await EmployeeDiscovery().discover(
      LocalHQSource(tempDir.path),
    );

    expect(result, ['marketing']);
  });

  test('discover() returns an alphabetically sorted list', () async {
    Directory('${tempDir.path}/employees/marketing').createSync();
    Directory('${tempDir.path}/employees/engineering').createSync();
    Directory('${tempDir.path}/employees/finance').createSync();

    final result = await EmployeeDiscovery().discover(
      LocalHQSource(tempDir.path),
    );

    expect(result, ['engineering', 'finance', 'marketing']);
  });
}
