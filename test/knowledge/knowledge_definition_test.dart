import 'package:pharos_ai_runtime/knowledge/knowledge_definition.dart';
import 'package:test/test.dart';

void main() {
  test('KnowledgeDefinition stores id, title, and content', () {
    const definition = KnowledgeDefinition(
      id: 'onboarding',
      title: 'Onboarding Guide',
      content: 'Welcome to the company.',
    );

    expect(definition.id, 'onboarding');
    expect(definition.title, 'Onboarding Guide');
    expect(definition.content, 'Welcome to the company.');
  });
}
