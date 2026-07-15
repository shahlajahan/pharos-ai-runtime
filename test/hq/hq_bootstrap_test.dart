import 'dart:io';

import 'package:pharos_ai_runtime/employees/employee_definition.dart';
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
import 'package:pharos_ai_runtime/prompts/markdown_prompt_parser.dart';
import 'package:pharos_ai_runtime/prompts/prompt_repository.dart';
import 'package:pharos_ai_runtime/runtime/employee_factory.dart';
import 'package:pharos_ai_runtime/runtime/employee_runtime.dart';
import 'package:test/test.dart';

class _EmployeeDiscoveryWithMissingEmployee extends EmployeeDiscovery {
  @override
  Future<List<String>> discover(HQSource source) async => ['ghost-employee'];
}

class _ThrowingEmployeeFactory extends EmployeeFactory {
  _ThrowingEmployeeFactory()
    : super(
        knowledgeRepository: KnowledgeRepository(
          parser: MarkdownKnowledgeParser(),
        ),
        promptRepository: PromptRepository(parser: MarkdownPromptParser()),
      );

  @override
  Future<EmployeeRuntime> create({
    required EmployeeDefinition definition,
    required Directory employeeDirectory,
  }) async {
    throw Exception('Simulated assembly failure.');
  }
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

HQBootstrap _bootstrap({
  EmployeeDiscovery? discovery,
  EmployeeFactory? employeeFactory,
}) => HQBootstrap(
  validator: HQValidator(),
  repository: EmployeeRepository(
    discovery: discovery ?? EmployeeDiscovery(),
    loader: EmployeeLoader(),
    parser: MarkdownEmployeeParser(),
  ),
  employeeFactory:
      employeeFactory ??
      EmployeeFactory(
        knowledgeRepository: KnowledgeRepository(
          parser: MarkdownKnowledgeParser(),
        ),
        promptRepository: PromptRepository(parser: MarkdownPromptParser()),
      ),
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
    Directory('${tempDir.path}/prompts').createSync();

    final result = await _bootstrap().boot(LocalHQSource(tempDir.path));

    expect(result.success, isTrue);
  });

  test(
    'boot() returns Result.failure when a discovered employee directory is missing',
    () async {
      Directory('${tempDir.path}/employees').createSync();
      Directory('${tempDir.path}/knowledge').createSync();
      Directory('${tempDir.path}/prompts').createSync();

      final bootstrap = _bootstrap(
        discovery: _EmployeeDiscoveryWithMissingEmployee(),
      );

      final result = await bootstrap.boot(LocalHQSource(tempDir.path));

      expect(result.success, isFalse);
    },
  );

  test('boot() returns Result.failure for a broken employee.md', () async {
    Directory(
      '${tempDir.path}/employees/marketing',
    ).createSync(recursive: true);
    File(
      '${tempDir.path}/employees/marketing/employee.md',
    ).writeAsStringSync('id: marketing\nname: Marketing Employee\n');
    Directory('${tempDir.path}/knowledge').createSync();
    Directory('${tempDir.path}/prompts').createSync();

    final result = await _bootstrap().boot(LocalHQSource(tempDir.path));

    expect(result.success, isFalse);
  });

  test(
    'boot() succeeds for a single employee with empty knowledge and prompts',
    () async {
      final employeeDir = Directory('${tempDir.path}/employees/marketing');
      _writeEmployeeMd(
        employeeDir,
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      );
      Directory('${employeeDir.path}/knowledge').createSync();
      Directory('${employeeDir.path}/prompts').createSync();
      Directory('${tempDir.path}/knowledge').createSync();
      Directory('${tempDir.path}/prompts').createSync();

      final result = await _bootstrap().boot(LocalHQSource(tempDir.path));

      expect(result.success, isTrue);
    },
  );

  test(
    'boot() succeeds for a single employee with knowledge and prompt documents',
    () async {
      final employeeDir = Directory('${tempDir.path}/employees/marketing');
      _writeEmployeeMd(
        employeeDir,
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      );
      Directory('${employeeDir.path}/knowledge').createSync();
      File('${employeeDir.path}/knowledge/onboarding.md').writeAsStringSync(
        '# Onboarding Guide\n\nWelcome.',
      );
      Directory('${employeeDir.path}/prompts').createSync();
      File(
        '${employeeDir.path}/prompts/marketing.md',
      ).writeAsStringSync('You are a marketing employee.');
      Directory('${tempDir.path}/knowledge').createSync();
      Directory('${tempDir.path}/prompts').createSync();

      final result = await _bootstrap().boot(LocalHQSource(tempDir.path));

      expect(result.success, isTrue);
    },
  );

  test(
    'boot() succeeds for multiple employees each with their own knowledge '
    'and prompts',
    () async {
      for (final id in ['marketing', 'engineering']) {
        final employeeDir = Directory('${tempDir.path}/employees/$id');
        _writeEmployeeMd(employeeDir, id: id, name: '$id Employee', role: id);
        Directory('${employeeDir.path}/knowledge').createSync();
        Directory('${employeeDir.path}/prompts').createSync();
      }
      Directory('${tempDir.path}/knowledge').createSync();
      Directory('${tempDir.path}/prompts').createSync();

      final result = await _bootstrap().boot(LocalHQSource(tempDir.path));

      expect(result.success, isTrue);
    },
  );

  test(
    'boot() returns Result.failure when an employee is missing its '
    'knowledge directory',
    () async {
      final employeeDir = Directory('${tempDir.path}/employees/marketing');
      _writeEmployeeMd(
        employeeDir,
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      );
      Directory('${employeeDir.path}/prompts').createSync();
      // employeeDir/knowledge is intentionally never created.
      Directory('${tempDir.path}/knowledge').createSync();
      Directory('${tempDir.path}/prompts').createSync();

      final result = await _bootstrap().boot(LocalHQSource(tempDir.path));

      expect(result.success, isFalse);
    },
  );

  test(
    'boot() returns Result.failure when an employee is missing its '
    'prompts directory',
    () async {
      final employeeDir = Directory('${tempDir.path}/employees/marketing');
      _writeEmployeeMd(
        employeeDir,
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      );
      Directory('${employeeDir.path}/knowledge').createSync();
      // employeeDir/prompts is intentionally never created.
      Directory('${tempDir.path}/knowledge').createSync();
      Directory('${tempDir.path}/prompts').createSync();

      final result = await _bootstrap().boot(LocalHQSource(tempDir.path));

      expect(result.success, isFalse);
    },
  );

  test(
    'boot() returns Result.failure when an employee knowledge document '
    'cannot be parsed',
    () async {
      final employeeDir = Directory('${tempDir.path}/employees/marketing');
      _writeEmployeeMd(
        employeeDir,
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      );
      Directory('${employeeDir.path}/knowledge').createSync();
      File(
        '${employeeDir.path}/knowledge/broken.md',
      ).writeAsStringSync('No heading here.');
      Directory('${employeeDir.path}/prompts').createSync();
      Directory('${tempDir.path}/knowledge').createSync();
      Directory('${tempDir.path}/prompts').createSync();

      final result = await _bootstrap().boot(LocalHQSource(tempDir.path));

      expect(result.success, isFalse);
    },
  );

  test('boot() returns Result.failure when EmployeeFactory throws', () async {
    final employeeDir = Directory('${tempDir.path}/employees/marketing');
    _writeEmployeeMd(
      employeeDir,
      id: 'marketing',
      name: 'Marketing Employee',
      role: 'Marketing',
    );
    Directory('${employeeDir.path}/knowledge').createSync();
    Directory('${employeeDir.path}/prompts').createSync();
    Directory('${tempDir.path}/knowledge').createSync();
    Directory('${tempDir.path}/prompts').createSync();

    final bootstrap = _bootstrap(employeeFactory: _ThrowingEmployeeFactory());

    final result = await bootstrap.boot(LocalHQSource(tempDir.path));

    expect(result.success, isFalse);
  });
}
