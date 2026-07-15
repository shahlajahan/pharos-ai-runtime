import 'package:pharos_ai_runtime/prompts/prompt_definition.dart';
import 'package:test/test.dart';

void main() {
  test('PromptDefinition stores id and content', () {
    const definition = PromptDefinition(
      id: 'marketing',
      content: 'You are a marketing employee.',
    );

    expect(definition.id, 'marketing');
    expect(definition.content, 'You are a marketing employee.');
  });
}
