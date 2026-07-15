import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/employees/employee_repository.dart';
import 'package:pharos_ai_runtime/hq/hq_source.dart';
import 'package:pharos_ai_runtime/hq/hq_validator.dart';

class HQBootstrap {
  HQBootstrap({
    required HQValidator validator,
    required EmployeeRepository repository,
  }) : _validator = validator,
       _repository = repository;

  final HQValidator _validator;
  final EmployeeRepository _repository;

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

    return Result.success('HQ bootstrapped successfully.');
  }
}
