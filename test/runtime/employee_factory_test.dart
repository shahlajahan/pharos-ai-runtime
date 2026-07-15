import 'dart:io';

import 'package:pharos_ai_runtime/employees/employee_definition.dart';
import 'package:pharos_ai_runtime/knowledge/knowledge_repository.dart';
import 'package:pharos_ai_runtime/knowledge/markdown_knowledge_parser.dart';
import 'package:pharos_ai_runtime/prompts/markdown_prompt_parser.dart';
import 'package:pharos_ai_runtime/prompts/prompt_repository.dart';
import 'package:pharos_ai_runtime/runtime/employee_factory.dart';
import 'package:test/test.dart';

EmployeeFactory _factory() => EmployeeFactory(
  knowledgeRepository: KnowledgeRepository(parser: MarkdownKnowledgeParser()),
  promptRepository: PromptRepository(parser: MarkdownPromptParser()),
);

const _definition = EmployeeDefinition(
  id: 'marketing',
  name: 'Marketing Employee',
  role: 'Marketing',
);

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('employee_factory_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test(
    'create() returns an EmployeeRuntime with empty lists for empty '
    'knowledge and prompts directories',
    () async {
      Directory('${tempDir.path}/knowledge').createSync();
      Directory('${tempDir.path}/prompts').createSync();

      final runtime = await _factory().create(
        definition: _definition,
        employeeDirectory: tempDir,
      );

      expect(runtime.definition, same(_definition));
      expect(runtime.knowledge, isEmpty);
      expect(runtime.prompts, isEmpty);
    },
  );

  test('create() loads valid knowledge documents', () async {
    Directory('${tempDir.path}/knowledge').createSync();
    File('${tempDir.path}/knowledge/onboarding.md').writeAsStringSync(
      '# Onboarding Guide\n\nWelcome.',
    );
    Directory('${tempDir.path}/prompts').createSync();

    final runtime = await _factory().create(
      definition: _definition,
      employeeDirectory: tempDir,
    );

    expect(runtime.knowledge, hasLength(1));
    expect(runtime.knowledge.first.id, 'onboarding');
    expect(runtime.knowledge.first.title, 'Onboarding Guide');
  });

  test('create() loads valid prompt documents', () async {
    Directory('${tempDir.path}/knowledge').createSync();
    Directory('${tempDir.path}/prompts').createSync();
    File(
      '${tempDir.path}/prompts/marketing.md',
    ).writeAsStringSync('You are a marketing employee.');

    final runtime = await _factory().create(
      definition: _definition,
      employeeDirectory: tempDir,
    );

    expect(runtime.prompts, hasLength(1));
    expect(runtime.prompts.first.id, 'marketing');
    expect(runtime.prompts.first.content, 'You are a marketing employee.');
  });

  test(
    'create() returns an EmployeeRuntime combining the given definition '
    'with loaded knowledge and prompts',
    () async {
      Directory('${tempDir.path}/knowledge').createSync();
      File('${tempDir.path}/knowledge/onboarding.md').writeAsStringSync(
        '# Onboarding Guide\n\nWelcome.',
      );
      Directory('${tempDir.path}/prompts').createSync();
      File(
        '${tempDir.path}/prompts/marketing.md',
      ).writeAsStringSync('You are a marketing employee.');

      final runtime = await _factory().create(
        definition: _definition,
        employeeDirectory: tempDir,
      );

      expect(runtime.definition, same(_definition));
      expect(runtime.knowledge, hasLength(1));
      expect(runtime.prompts, hasLength(1));
    },
  );
}
