import 'dart:io';

import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/employees/employee_repository.dart';
import 'package:pharos_ai_runtime/hq/hq_source.dart';
import 'package:pharos_ai_runtime/hq/hq_validator.dart';
import 'package:pharos_ai_runtime/knowledge/knowledge_repository.dart';
import 'package:pharos_ai_runtime/prompts/prompt_repository.dart';

class HQBootstrap {
  HQBootstrap({
    required HQValidator validator,
    required EmployeeRepository repository,
    required KnowledgeRepository knowledgeRepository,
    required PromptRepository promptRepository,
  }) : _validator = validator,
       _repository = repository,
       _knowledgeRepository = knowledgeRepository,
       _promptRepository = promptRepository;

  final HQValidator _validator;
  final EmployeeRepository _repository;
  final KnowledgeRepository _knowledgeRepository;
  final PromptRepository _promptRepository;

  Future<Result> boot(HQSource source) async {
    final validation = await _validator.validate(source);

    if (!validation.success) {
      return validation;
    }

    try {
      await _repository.load(source);
    } catch (e) {
      return Result.failure('Failed to load employees: $e');
    }

    final rootPath = await source.rootPath();

    try {
      await _knowledgeRepository.load(Directory('$rootPath/knowledge'));
    } catch (e) {
      return Result.failure('Failed to load knowledge: $e');
    }

    try {
      await _promptRepository.load(Directory('$rootPath/prompts'));
    } catch (e) {
      return Result.failure('Failed to load prompts: $e');
    }

    return Result.success('HQ bootstrapped successfully.');
  }
}
