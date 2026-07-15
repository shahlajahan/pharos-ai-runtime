import 'package:pharos_ai_runtime/employees/employee_definition.dart';
import 'package:pharos_ai_runtime/knowledge/knowledge_definition.dart';
import 'package:pharos_ai_runtime/prompts/prompt_definition.dart';
import 'package:pharos_ai_runtime/runtime/employee_runtime.dart';
import 'package:test/test.dart';

void main() {
  test(
    'EmployeeRuntime stores definition, knowledge, and prompts',
    () {
      const definition = EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      );
      const knowledge = [
        KnowledgeDefinition(
          id: 'onboarding',
          title: 'Onboarding Guide',
          content: 'Welcome to the company.',
        ),
      ];
      const prompts = [
        PromptDefinition(
          id: 'marketing',
          content: 'You are a marketing employee.',
        ),
      ];

      const runtime = EmployeeRuntime(
        definition: definition,
        knowledge: knowledge,
        prompts: prompts,
      );

      expect(runtime.definition, same(definition));
      expect(runtime.knowledge, same(knowledge));
      expect(runtime.prompts, same(prompts));
    },
  );
}
