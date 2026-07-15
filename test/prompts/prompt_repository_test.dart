import 'dart:io';

import 'package:pharos_ai_runtime/prompts/markdown_prompt_parser.dart';
import 'package:pharos_ai_runtime/prompts/prompt_repository.dart';
import 'package:test/test.dart';

PromptRepository _repository() =>
    PromptRepository(parser: MarkdownPromptParser());

void _writePrompt(Directory dir, String filename, String content) {
  File('${dir.path}/$filename').writeAsStringSync(content);
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('prompt_repository_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('load() returns [] for an empty directory', () async {
    final result = await _repository().load(tempDir);

    expect(result, isEmpty);
  });

  test('load() returns one PromptDefinition for one markdown file', () async {
    _writePrompt(tempDir, 'marketing.md', 'You are a marketing employee.');

    final result = await _repository().load(tempDir);

    expect(result, hasLength(1));
    expect(result.first.id, 'marketing');
    expect(result.first.content, 'You are a marketing employee.');
  });

  test('load() returns an ordered list for multiple markdown files', () async {
    _writePrompt(tempDir, 'zeta.md', 'Zeta prompt.');
    _writePrompt(tempDir, 'alpha.md', 'Alpha prompt.');
    _writePrompt(tempDir, 'mid.md', 'Mid prompt.');

    final result = await _repository().load(tempDir);

    expect(result.map((definition) => definition.id).toList(), [
      'alpha',
      'mid',
      'zeta',
    ]);
  });

  test('load() ignores hidden files', () async {
    _writePrompt(tempDir, '.hidden.md', 'Hidden prompt.');
    _writePrompt(tempDir, 'visible.md', 'Visible prompt.');

    final result = await _repository().load(tempDir);

    expect(result.map((definition) => definition.id).toList(), ['visible']);
  });

  test('load() ignores non-markdown files', () async {
    File('${tempDir.path}/notes.txt').writeAsStringSync('not markdown');
    _writePrompt(tempDir, 'visible.md', 'Visible prompt.');

    final result = await _repository().load(tempDir);

    expect(result.map((definition) => definition.id).toList(), ['visible']);
  });
}
