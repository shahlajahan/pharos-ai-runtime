import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/employees/employee_definition.dart';
import 'package:pharos_ai_runtime/employees/employee_repository.dart';
import 'package:pharos_ai_runtime/hq/employee_loader.dart';
import 'package:pharos_ai_runtime/hq/hq_source.dart';
import 'package:pharos_ai_runtime/hq/hq_validator.dart';
import 'package:pharos_ai_runtime/runtime/employee_factory.dart';

class HQBootstrap {
  HQBootstrap({
    required HQValidator validator,
    required EmployeeRepository repository,
    required EmployeeLoader loader,
    required EmployeeFactory employeeFactory,
  }) : _validator = validator,
       _repository = repository,
       _loader = loader,
       _employeeFactory = employeeFactory;

  final HQValidator _validator;
  final EmployeeRepository _repository;
  final EmployeeLoader _loader;
  final EmployeeFactory _employeeFactory;

  Future<Result> boot(HQSource source) async {
    final validation = await _validator.validate(source);

    if (!validation.success) {
      return validation;
    }

    List<EmployeeDefinition> definitions;

    try {
      definitions = await _repository.load(source);
    } catch (e) {
      return Result.failure('Failed to load employees: $e');
    }

    try {
      for (final definition in definitions) {
        final employeeDirectory = await _loader.load(source, definition.id);

        if (employeeDirectory == null) {
          throw Exception(
            'Employee directory not found for "${definition.id}".',
          );
        }

        await _employeeFactory.create(
          definition: definition,
          employeeDirectory: employeeDirectory,
        );
      }
    } catch (e) {
      return Result.failure('Failed to assemble employee runtime: $e');
    }

    return Result.success('HQ bootstrapped successfully.');
  }
}
