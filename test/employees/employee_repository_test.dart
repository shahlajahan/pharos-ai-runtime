import 'dart:io';

import 'package:pharos_ai_runtime/employees/employee_repository.dart';
import 'package:pharos_ai_runtime/employees/markdown_employee_parser.dart';
import 'package:pharos_ai_runtime/hq/employee_discovery.dart';
import 'package:pharos_ai_runtime/hq/employee_loader.dart';
import 'package:pharos_ai_runtime/hq/hq_source.dart';
import 'package:pharos_ai_runtime/hq/local_hq_source.dart';
import 'package:test/test.dart';

class _EmployeeDiscoveryWithMissingEmployee extends EmployeeDiscovery {
  @override
  Future<List<String>> discover(HQSource source) async => ['ghost-employee'];
}

void _writeEmployeeMd(
  Directory employeeDir, {
  required String id,
  required String name,
  required String role,
}) {
  employeeDir.createSync(recursive: true);
  File('${employeeDir.path}/employee.md').writeAsStringSync('''
id: $id
name: $name
role: $role
''');
}

EmployeeRepository _repository({EmployeeDiscovery? discovery}) =>
    EmployeeRepository(
      discovery: discovery ?? EmployeeDiscovery(),
      loader: EmployeeLoader(),
      parser: MarkdownEmployeeParser(),
    );

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync(
      'employee_repository_test_',
    );
    Directory('${tempDir.path}/employees').createSync();
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('load() returns [] for an HQ with no employees', () async {
    final result = await _repository().load(LocalHQSource(tempDir.path));

    expect(result, isEmpty);
  });

  test('load() returns one EmployeeDefinition for one employee', () async {
    _writeEmployeeMd(
      Directory('${tempDir.path}/employees/marketing'),
      id: 'marketing',
      name: 'Marketing Employee',
      role: 'Marketing',
    );

    final result = await _repository().load(LocalHQSource(tempDir.path));

    expect(result, hasLength(1));
    expect(result.first.definition.id, 'marketing');
    expect(result.first.definition.name, 'Marketing Employee');
    expect(result.first.definition.role, 'Marketing');
  });

  test(
    'load() returns the resolved Directory alongside each EmployeeDefinition',
    () async {
      final employeeDir = Directory('${tempDir.path}/employees/marketing');
      _writeEmployeeMd(
        employeeDir,
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      );

      final result = await _repository().load(LocalHQSource(tempDir.path));

      expect(result.first.directory.path, employeeDir.path);
    },
  );

  test('load() returns an ordered list for multiple employees', () async {
    _writeEmployeeMd(
      Directory('${tempDir.path}/employees/marketing'),
      id: 'marketing',
      name: 'Marketing Employee',
      role: 'Marketing',
    );
    _writeEmployeeMd(
      Directory('${tempDir.path}/employees/engineering'),
      id: 'engineering',
      name: 'Engineering Employee',
      role: 'Engineering',
    );
    _writeEmployeeMd(
      Directory('${tempDir.path}/employees/finance'),
      id: 'finance',
      name: 'Finance Employee',
      role: 'Finance',
    );

    final result = await _repository().load(LocalHQSource(tempDir.path));

    expect(
      result.map((employee) => employee.definition.id).toList(),
      ['engineering', 'finance', 'marketing'],
    );
  });

  test(
    'load() throws FileSystemException when a discovered employee '
    'directory is missing',
    () async {
      final repository = _repository(
        discovery: _EmployeeDiscoveryWithMissingEmployee(),
      );

      expect(
        () => repository.load(LocalHQSource(tempDir.path)),
        throwsA(isA<FileSystemException>()),
      );
    },
  );
}
