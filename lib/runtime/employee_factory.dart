import 'dart:io';

import 'package:pharos_ai_runtime/employees/employee_definition.dart';
import 'package:pharos_ai_runtime/knowledge/knowledge_repository.dart';
import 'package:pharos_ai_runtime/prompts/prompt_repository.dart';
import 'package:pharos_ai_runtime/runtime/employee_runtime.dart';

class EmployeeFactory {
  EmployeeFactory({
    required KnowledgeRepository knowledgeRepository,
    required PromptRepository promptRepository,
  }) : _knowledgeRepository = knowledgeRepository,
       _promptRepository = promptRepository;

  final KnowledgeRepository _knowledgeRepository;
  final PromptRepository _promptRepository;

  Future<EmployeeRuntime> create({
    required EmployeeDefinition definition,
    required Directory employeeDirectory,
  }) async {
    final knowledge = await _knowledgeRepository.load(
      Directory('${employeeDirectory.path}/knowledge'),
    );
    final prompts = await _promptRepository.load(
      Directory('${employeeDirectory.path}/prompts'),
    );

    return EmployeeRuntime(
      definition: definition,
      knowledge: knowledge,
      prompts: prompts,
    );
  }
}
