import 'dart:io';

import 'package:pharos_ai_runtime/employees/employee_definition.dart';
import 'package:pharos_ai_runtime/employees/employee_parser.dart';
import 'package:pharos_ai_runtime/hq/employee_discovery.dart';
import 'package:pharos_ai_runtime/hq/employee_loader.dart';
import 'package:pharos_ai_runtime/hq/hq_source.dart';

class EmployeeRepository {
  EmployeeRepository({
    required EmployeeDiscovery discovery,
    required EmployeeLoader loader,
    required EmployeeParser parser,
  }) : _discovery = discovery,
       _loader = loader,
       _parser = parser;

  final EmployeeDiscovery _discovery;
  final EmployeeLoader _loader;
  final EmployeeParser _parser;

  Future<List<EmployeeDefinition>> load(HQSource source) async {
    final employeeIds = await _discovery.discover(source);
    final definitions = <EmployeeDefinition>[];

    for (final employeeId in employeeIds) {
      final directory = await _loader.load(source, employeeId);

      if (directory == null) {
        throw FileSystemException(
          'Employee directory not found for "$employeeId".',
        );
      }

      definitions.add(await _parser.parse(directory));
    }

    return definitions;
  }
}
