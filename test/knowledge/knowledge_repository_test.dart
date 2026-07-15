import 'dart:io';

import 'package:pharos_ai_runtime/knowledge/knowledge_repository.dart';
import 'package:pharos_ai_runtime/knowledge/markdown_knowledge_parser.dart';
import 'package:test/test.dart';

KnowledgeRepository _repository() =>
    KnowledgeRepository(parser: MarkdownKnowledgeParser());

void _writeMarkdown(Directory dir, String filename, String heading) {
  File('${dir.path}/$filename').writeAsStringSync('# $heading\n\nContent.');
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync(
      'knowledge_repository_test_',
    );
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

  test(
    'load() returns one KnowledgeDefinition for one markdown file',
    () async {
      _writeMarkdown(tempDir, 'onboarding.md', 'Onboarding Guide');

      final result = await _repository().load(tempDir);

      expect(result, hasLength(1));
      expect(result.first.id, 'onboarding');
      expect(result.first.title, 'Onboarding Guide');
    },
  );

  test('load() returns an ordered list for multiple markdown files', () async {
    _writeMarkdown(tempDir, 'zeta.md', 'Zeta');
    _writeMarkdown(tempDir, 'alpha.md', 'Alpha');
    _writeMarkdown(tempDir, 'mid.md', 'Mid');

    final result = await _repository().load(tempDir);

    expect(result.map((definition) => definition.id).toList(), [
      'alpha',
      'mid',
      'zeta',
    ]);
  });

  test('load() ignores hidden files', () async {
    _writeMarkdown(tempDir, '.hidden.md', 'Hidden');
    _writeMarkdown(tempDir, 'visible.md', 'Visible');

    final result = await _repository().load(tempDir);

    expect(result.map((definition) => definition.id).toList(), ['visible']);
  });

  test('load() ignores non-markdown files', () async {
    File('${tempDir.path}/notes.txt').writeAsStringSync('not markdown');
    _writeMarkdown(tempDir, 'visible.md', 'Visible');

    final result = await _repository().load(tempDir);

    expect(result.map((definition) => definition.id).toList(), ['visible']);
  });
}
