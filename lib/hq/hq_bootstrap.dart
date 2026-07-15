import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/employees/employee_repository.dart';
import 'package:pharos_ai_runtime/employees/loaded_employee.dart';
import 'package:pharos_ai_runtime/hq/hq_source.dart';
import 'package:pharos_ai_runtime/hq/hq_validator.dart';
import 'package:pharos_ai_runtime/runtime/employee_factory.dart';

class HQBootstrap {
  HQBootstrap({
    required HQValidator validator,
    required EmployeeRepository repository,
    required EmployeeFactory employeeFactory,
  }) : _validator = validator,
       _repository = repository,
       _employeeFactory = employeeFactory;

  final HQValidator _validator;
  final EmployeeRepository _repository;
  final EmployeeFactory _employeeFactory;

  Future<Result> boot(HQSource source) async {
    final validation = await _validator.validate(source);

    if (!validation.success) {
      return validation;
    }

    List<LoadedEmployee> employees;

    try {
      employees = await _repository.load(source);
    } catch (e) {
      return Result.failure('Failed to load employees: $e');
    }

    try {
      for (final employee in employees) {
        await _employeeFactory.create(
          definition: employee.definition,
          employeeDirectory: employee.directory,
        );
      }
    } catch (e) {
      return Result.failure('Failed to assemble employee runtime: $e');
    }

    return Result.success('HQ bootstrapped successfully.');
  }
}
