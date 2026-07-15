import 'dart:io';

import 'package:pharos_ai_runtime/knowledge/markdown_knowledge_parser.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync(
      'markdown_knowledge_parser_test_',
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test(
    'parse() returns a KnowledgeDefinition for a valid markdown file',
    () async {
      final file = File('${tempDir.path}/onboarding.md');
      file.writeAsStringSync('''
# Onboarding Guide

Welcome to the company.
''');

      final definition = await MarkdownKnowledgeParser().parse(file);

      expect(definition.id, 'onboarding');
      expect(definition.title, 'Onboarding Guide');
      expect(definition.content, file.readAsStringSync());
    },
  );

  test(
    'parse() throws FileSystemException when the file is missing',
    () async {
      final file = File('${tempDir.path}/missing.md');

      expect(
        () => MarkdownKnowledgeParser().parse(file),
        throwsA(isA<FileSystemException>()),
      );
    },
  );

  test(
    'parse() throws FormatException when no markdown heading exists',
    () async {
      final file = File('${tempDir.path}/no-heading.md');
      file.writeAsStringSync('Just some text with no heading.');

      expect(
        () => MarkdownKnowledgeParser().parse(file),
        throwsA(isA<FormatException>()),
      );
    },
  );
}
