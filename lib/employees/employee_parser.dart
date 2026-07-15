import 'dart:io';

import 'package:pharos_ai_runtime/employees/employee_definition.dart';

abstract class EmployeeParser {
  Future<EmployeeDefinition> parse(Directory directory);
}
