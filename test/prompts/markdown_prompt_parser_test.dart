import 'dart:io';

import 'package:pharos_ai_runtime/prompts/markdown_prompt_parser.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync(
      'markdown_prompt_parser_test_',
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('parse() returns a PromptDefinition for a valid file', () async {
    final file = File('${tempDir.path}/marketing.md');
    file.writeAsStringSync('You are a marketing employee.');

    final definition = await MarkdownPromptParser().parse(file);

    expect(definition.id, 'marketing');
    expect(definition.content, 'You are a marketing employee.');
  });

  test(
    'parse() throws FileSystemException when the file is missing',
    () async {
      final file = File('${tempDir.path}/missing.md');

      expect(
        () => MarkdownPromptParser().parse(file),
        throwsA(isA<FileSystemException>()),
      );
    },
  );

  test('parse() preserves the entire file content exactly', () async {
    final file = File('${tempDir.path}/marketing.md');
    const rawContent = '''
  Leading and trailing whitespace should survive.

  # Not a required heading

  Multiple

  blank

  lines.
''';
    file.writeAsStringSync(rawContent);

    final definition = await MarkdownPromptParser().parse(file);

    expect(definition.content, rawContent);
  });
}
