import 'dart:io';

import 'package:pharos_ai_runtime/employees/employee_definition.dart';

class LoadedEmployee {
  const LoadedEmployee({required this.definition, required this.directory});

  final EmployeeDefinition definition;
  final Directory directory;
}
