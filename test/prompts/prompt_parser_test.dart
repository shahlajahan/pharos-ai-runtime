import 'dart:io';

import 'package:pharos_ai_runtime/prompts/prompt_definition.dart';
import 'package:pharos_ai_runtime/prompts/prompt_parser.dart';
import 'package:test/test.dart';

class _FakePromptParser extends PromptParser {
  @override
  Future<PromptDefinition> parse(File file) async {
    return const PromptDefinition(
      id: 'marketing',
      content: 'You are a marketing employee.',
    );
  }
}

void main() {
  test(
    'PromptParser exposes parse(File) returning PromptDefinition',
    () async {
      final parser = _FakePromptParser();

      final definition = await parser.parse(File('/some/prompt/doc.md'));

      expect(definition.id, 'marketing');
      expect(definition.content, 'You are a marketing employee.');
    },
  );
}
