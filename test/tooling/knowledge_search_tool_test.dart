import 'package:pharos_ai_runtime/knowledge/knowledge_definition.dart';
import 'package:pharos_ai_runtime/tooling/knowledge_search_tool.dart';
import 'package:pharos_ai_runtime/tooling/tool_context.dart';
import 'package:test/test.dart';

void main() {
  const commissionDoc = KnowledgeDefinition(
    id: 'commission-engine',
    title: 'Commission Engine',
    content:
        '# Commission Engine\n\nThe commission engine calculates payouts '
        'based on tiered sales targets.',
  );
  const onboardingDoc = KnowledgeDefinition(
    id: 'onboarding',
    title: 'Onboarding Guide',
    content: '# Onboarding Guide\n\nWelcome to the team.',
  );

  test('id is "knowledge_search"', () {
    final tool = KnowledgeSearchTool(knowledge: const []);

    expect(tool.id, 'knowledge_search');
  });

  test('execute() matches by title', () async {
    final tool = KnowledgeSearchTool(
      knowledge: const [commissionDoc, onboardingDoc],
    );

    final result = await tool.execute(
      const ToolContext(
        toolId: 'knowledge_search',
        arguments: '{"query":"Commission Engine"}',
      ),
    );

    expect(result.success, isTrue);
    expect(result.message, contains('tiered sales targets'));
    expect(result.message, isNot(contains('Welcome to the team')));
  });

  test('execute() matches by filename (id)', () async {
    final tool = KnowledgeSearchTool(
      knowledge: const [commissionDoc, onboardingDoc],
    );

    final result = await tool.execute(
      const ToolContext(
        toolId: 'knowledge_search',
        arguments: '{"query":"commission-engine"}',
      ),
    );

    expect(result.success, isTrue);
    expect(result.message, contains('tiered sales targets'));
  });

  test('execute() matches by keyword in content', () async {
    final tool = KnowledgeSearchTool(
      knowledge: const [commissionDoc, onboardingDoc],
    );

    final result = await tool.execute(
      const ToolContext(
        toolId: 'knowledge_search',
        arguments: '{"query":"payouts"}',
      ),
    );

    expect(result.success, isTrue);
    expect(result.message, contains('tiered sales targets'));
  });

  test('execute() matching is case-insensitive', () async {
    final tool = KnowledgeSearchTool(knowledge: const [commissionDoc]);

    final result = await tool.execute(
      const ToolContext(
        toolId: 'knowledge_search',
        arguments: '{"query":"COMMISSION ENGINE"}',
      ),
    );

    expect(result.success, isTrue);
    expect(result.message, contains('tiered sales targets'));
  });

  test('execute() returns every matching document, joined, when more than '
      'one document matches', () async {
    const secondCommissionDoc = KnowledgeDefinition(
      id: 'commission-faq',
      title: 'Commission FAQ',
      content: '# Commission FAQ\n\nCommon commission questions answered.',
    );
    final tool = KnowledgeSearchTool(
      knowledge: const [commissionDoc, onboardingDoc, secondCommissionDoc],
    );

    final result = await tool.execute(
      const ToolContext(
        toolId: 'knowledge_search',
        arguments: '{"query":"commission"}',
      ),
    );

    expect(result.success, isTrue);
    expect(result.message, contains('tiered sales targets'));
    expect(result.message, contains('Common commission questions'));
    expect(result.message, isNot(contains('Welcome to the team')));
  });

  test('execute() succeeds with a "no matching knowledge" message when '
      'nothing matches', () async {
    final tool = KnowledgeSearchTool(
      knowledge: const [commissionDoc, onboardingDoc],
    );

    final result = await tool.execute(
      const ToolContext(
        toolId: 'knowledge_search',
        arguments: '{"query":"quantum computing"}',
      ),
    );

    expect(result.success, isTrue);
    expect(result.message, contains('No matching knowledge found'));
  });

  test('execute() only ever searches the knowledge it was constructed '
      'with, never other documents', () async {
    final tool = KnowledgeSearchTool(knowledge: const [onboardingDoc]);

    final result = await tool.execute(
      const ToolContext(
        toolId: 'knowledge_search',
        arguments: '{"query":"commission"}',
      ),
    );

    expect(result.success, isTrue);
    expect(result.message, contains('No matching knowledge found'));
  });

  test('execute() returns Result.failure for invalid JSON arguments', () async {
    final tool = KnowledgeSearchTool(knowledge: const [commissionDoc]);

    final result = await tool.execute(
      const ToolContext(toolId: 'knowledge_search', arguments: 'not json'),
    );

    expect(result.success, isFalse);
  });

  test(
    'execute() returns Result.failure when arguments is not a JSON object',
    () async {
      final tool = KnowledgeSearchTool(knowledge: const [commissionDoc]);

      final result = await tool.execute(
        const ToolContext(toolId: 'knowledge_search', arguments: '[]'),
      );

      expect(result.success, isFalse);
    },
  );

  test('execute() returns Result.failure when "query" is missing', () async {
    final tool = KnowledgeSearchTool(knowledge: const [commissionDoc]);

    final result = await tool.execute(
      const ToolContext(toolId: 'knowledge_search', arguments: '{}'),
    );

    expect(result.success, isFalse);
  });

  test('execute() returns Result.failure when "query" is empty', () async {
    final tool = KnowledgeSearchTool(knowledge: const [commissionDoc]);

    final result = await tool.execute(
      const ToolContext(toolId: 'knowledge_search', arguments: '{"query":""}'),
    );

    expect(result.success, isFalse);
  });
}
