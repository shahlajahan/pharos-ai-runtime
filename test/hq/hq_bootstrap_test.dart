import 'dart:io';

import 'package:pharos_ai_runtime/employees/employee_repository.dart';
import 'package:pharos_ai_runtime/employees/markdown_employee_parser.dart';
import 'package:pharos_ai_runtime/hq/employee_discovery.dart';
import 'package:pharos_ai_runtime/hq/employee_loader.dart';
import 'package:pharos_ai_runtime/hq/hq_bootstrap.dart';
import 'package:pharos_ai_runtime/hq/hq_source.dart';
import 'package:pharos_ai_runtime/hq/hq_validator.dart';
import 'package:pharos_ai_runtime/hq/local_hq_source.dart';
import 'package:pharos_ai_runtime/knowledge/knowledge_repository.dart';
import 'package:pharos_ai_runtime/knowledge/markdown_knowledge_parser.dart';
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

HQBootstrap _bootstrap({EmployeeDiscovery? discovery}) => HQBootstrap(
  validator: HQValidator(),
  repository: EmployeeRepository(
    discovery: discovery ?? EmployeeDiscovery(),
    loader: EmployeeLoader(),
    parser: MarkdownEmployeeParser(),
  ),
  knowledgeRepository: KnowledgeRepository(parser: MarkdownKnowledgeParser()),
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
    Directory('${tempDir.path}/knowledge').createSync();
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

  test('boot() succeeds for an HQ with valid knowledge documents', () async {
    Directory('${tempDir.path}/employees').createSync();
    Directory('${tempDir.path}/knowledge').createSync();
    File('${tempDir.path}/knowledge/onboarding.md').writeAsStringSync(
      '# Onboarding Guide\n\nWelcome.',
    );

    final result = await _bootstrap().boot(LocalHQSource(tempDir.path));

    expect(result.success, isTrue);
  });

  test(
    'boot() returns Result.failure when a knowledge document cannot be parsed',
    () async {
      Directory('${tempDir.path}/employees').createSync();
      Directory('${tempDir.path}/knowledge').createSync();
      File(
        '${tempDir.path}/knowledge/broken.md',
      ).writeAsStringSync('No heading here.');

      final result = await _bootstrap().boot(LocalHQSource(tempDir.path));

      expect(result.success, isFalse);
    },
  );

  test(
    'boot() succeeds for a valid HQ with both an employee and knowledge',
    () async {
      _writeEmployeeMd(
        Directory('${tempDir.path}/employees/marketing'),
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      );
      Directory('${tempDir.path}/knowledge').createSync();
      File('${tempDir.path}/knowledge/onboarding.md').writeAsStringSync(
        '# Onboarding Guide\n\nWelcome.',
      );

      final result = await _bootstrap().boot(LocalHQSource(tempDir.path));

      expect(result.success, isTrue);
    },
  );

  test(
    'boot() succeeds when the knowledge directory is empty',
    () async {
      _writeEmployeeMd(
        Directory('${tempDir.path}/employees/marketing'),
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      );
      Directory('${tempDir.path}/knowledge').createSync();

      final result = await _bootstrap().boot(LocalHQSource(tempDir.path));

      expect(result.success, isTrue);
    },
  );

  test(
    'boot() returns Result.failure for a broken employee.md',
    () async {
      Directory('${tempDir.path}/employees/marketing').createSync(
        recursive: true,
      );
      File(
        '${tempDir.path}/employees/marketing/employee.md',
      ).writeAsStringSync('id: marketing\nname: Marketing Employee\n');
      Directory('${tempDir.path}/knowledge').createSync();

      final result = await _bootstrap().boot(LocalHQSource(tempDir.path));

      expect(result.success, isFalse);
    },
  );

  test(
    'boot() returns Result.failure for a broken knowledge markdown document',
    () async {
      _writeEmployeeMd(
        Directory('${tempDir.path}/employees/marketing'),
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      );
      Directory('${tempDir.path}/knowledge').createSync();
      File(
        '${tempDir.path}/knowledge/broken.md',
      ).writeAsStringSync('No heading in this document.');

      final result = await _bootstrap().boot(LocalHQSource(tempDir.path));

      expect(result.success, isFalse);
    },
  );
}
