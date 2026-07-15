import 'dart:io';

import 'package:pharos_ai_runtime/hq/employee_loader.dart';
import 'package:pharos_ai_runtime/hq/local_hq_source.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('employee_loader_test_');
    Directory('${tempDir.path}/employees').createSync();
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('load() returns the Directory for an existing employee', () async {
    Directory('${tempDir.path}/employees/marketing').createSync();

    final result = await EmployeeLoader().load(
      LocalHQSource(tempDir.path),
      'marketing',
    );

    expect(result, isNotNull);
    expect(result, isA<Directory>());
  });

  test('load() returns null for a missing employee', () async {
    final result = await EmployeeLoader().load(
      LocalHQSource(tempDir.path),
      'missing',
    );

    expect(result, isNull);
  });

  test('load() returns a Directory pointing to the expected path', () async {
    Directory('${tempDir.path}/employees/marketing').createSync();

    final result = await EmployeeLoader().load(
      LocalHQSource(tempDir.path),
      'marketing',
    );

    expect(result!.path, '${tempDir.path}/employees/marketing');
  });

  test('load() never inspects the directory contents', () async {
    final employeeDir = Directory('${tempDir.path}/employees/marketing')
      ..createSync();
    File('${employeeDir.path}/employee.md').createSync();

    final result = await EmployeeLoader().load(
      LocalHQSource(tempDir.path),
      'marketing',
    );

    expect(result, isNotNull);
    expect(result, isA<Directory>());
  });
}
