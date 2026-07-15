import 'dart:io';

import 'package:pharos_ai_runtime/knowledge/knowledge_definition.dart';
import 'package:pharos_ai_runtime/knowledge/knowledge_parser.dart';
import 'package:test/test.dart';

class _FakeKnowledgeParser extends KnowledgeParser {
  @override
  Future<KnowledgeDefinition> parse(File file) async {
    return const KnowledgeDefinition(
      id: 'onboarding',
      title: 'Onboarding Guide',
      content: 'Welcome to the company.',
    );
  }
}

void main() {
  test(
    'KnowledgeParser exposes parse(File) returning KnowledgeDefinition',
    () async {
      final parser = _FakeKnowledgeParser();

      final definition = await parser.parse(File('/some/knowledge/doc.md'));

      expect(definition.id, 'onboarding');
      expect(definition.title, 'Onboarding Guide');
      expect(definition.content, 'Welcome to the company.');
    },
  );
}
