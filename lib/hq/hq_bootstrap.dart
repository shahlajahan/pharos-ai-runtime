import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/employees/employee_repository.dart';
import 'package:pharos_ai_runtime/employees/loaded_employee.dart';
import 'package:pharos_ai_runtime/hq/hq_boot_result.dart';
import 'package:pharos_ai_runtime/hq/hq_source.dart';
import 'package:pharos_ai_runtime/hq/hq_validator.dart';
import 'package:pharos_ai_runtime/runtime/employee_factory.dart';
import 'package:pharos_ai_runtime/runtime/employee_runtime.dart';

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

  Future<HQBootResult> boot(HQSource source) async {
    final validation = await _validator.validate(source);

    if (!validation.success) {
      return HQBootResult(result: validation, employees: const []);
    }

    List<LoadedEmployee> employees;

    try {
      employees = await _repository.load(source);
    } catch (e) {
      return HQBootResult(
        result: Result.failure('Failed to load employees: $e'),
        employees: const [],
      );
    }

    final collectedEmployees = <EmployeeRuntime>[];

    try {
      for (final employee in employees) {
        final employeeRuntime = await _employeeFactory.create(
          definition: employee.definition,
          employeeDirectory: employee.directory,
        );
        collectedEmployees.add(employeeRuntime);
      }
    } catch (e) {
      return HQBootResult(
        result: Result.failure('Failed to assemble employee runtime: $e'),
        employees: const [],
      );
    }

    return HQBootResult(
      result: Result.success('HQ bootstrapped successfully.'),
      employees: collectedEmployees,
    );
  }
}
