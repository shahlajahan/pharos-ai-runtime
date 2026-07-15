import 'dart:io';

import 'package:pharos_ai_runtime/employees/markdown_employee_parser.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync(
      'markdown_employee_parser_test_',
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test(
    'parse() returns an EmployeeDefinition for a valid employee.md',
    () async {
      File('${tempDir.path}/employee.md').writeAsStringSync('''
id: marketing
name: Marketing Employee
role: Marketing
''');

      final definition = await MarkdownEmployeeParser().parse(tempDir);

      expect(definition.id, 'marketing');
      expect(definition.name, 'Marketing Employee');
      expect(definition.role, 'Marketing');
    },
  );

  test(
    'parse() throws FileSystemException when employee.md is missing',
    () async {
      expect(
        () => MarkdownEmployeeParser().parse(tempDir),
        throwsA(isA<FileSystemException>()),
      );
    },
  );

  test(
    'parse() throws FormatException when a required field is missing',
    () async {
      File('${tempDir.path}/employee.md').writeAsStringSync('''
id: marketing
name: Marketing Employee
''');

      expect(
        () => MarkdownEmployeeParser().parse(tempDir),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test('parse() ignores unknown metadata keys', () async {
    File('${tempDir.path}/employee.md').writeAsStringSync('''
id: marketing
name: Marketing Employee
role: Marketing
prompt: some/other/thing
unknown_key: whatever
''');

    final definition = await MarkdownEmployeeParser().parse(tempDir);

    expect(definition.id, 'marketing');
    expect(definition.name, 'Marketing Employee');
    expect(definition.role, 'Marketing');
  });

  test('parse() ignores blank lines and trims whitespace', () async {
    File('${tempDir.path}/employee.md').writeAsStringSync('''

  id:   marketing
  name:   Marketing Employee

  role:   Marketing

''');

    final definition = await MarkdownEmployeeParser().parse(tempDir);

    expect(definition.id, 'marketing');
    expect(definition.name, 'Marketing Employee');
    expect(definition.role, 'Marketing');
  });
}
