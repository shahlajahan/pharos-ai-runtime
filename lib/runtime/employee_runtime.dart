import 'package:pharos_ai_runtime/employees/employee_definition.dart';
import 'package:pharos_ai_runtime/knowledge/knowledge_definition.dart';
import 'package:pharos_ai_runtime/prompts/prompt_definition.dart';

class EmployeeRuntime {
  const EmployeeRuntime({
    required this.definition,
    required this.knowledge,
    required this.prompts,
  });

  final EmployeeDefinition definition;
  final List<KnowledgeDefinition> knowledge;
  final List<PromptDefinition> prompts;
}
