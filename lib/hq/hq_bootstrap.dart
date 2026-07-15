import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/hq/employee_discovery.dart';
import 'package:pharos_ai_runtime/hq/employee_loader.dart';
import 'package:pharos_ai_runtime/hq/hq_source.dart';
import 'package:pharos_ai_runtime/hq/hq_validator.dart';

class HQBootstrap {
  HQBootstrap({
    required HQValidator validator,
    required EmployeeDiscovery discovery,
    required EmployeeLoader loader,
  }) : _validator = validator,
       _discovery = discovery,
       _loader = loader;

  final HQValidator _validator;
  final EmployeeDiscovery _discovery;
  final EmployeeLoader _loader;

  Future<Result> boot(HQSource source) async {
    final validation = await _validator.validate(source);

    if (!validation.success) {
      return validation;
    }

    final employeeIds = await _discovery.discover(source);

    for (final employeeId in employeeIds) {
      final employeeDirectory = await _loader.load(source, employeeId);

      if (employeeDirectory == null) {
        return Result.failure('Employee "$employeeId" could not be loaded.');
      }
    }

    return Result.success('HQ bootstrapped successfully.');
  }
}
