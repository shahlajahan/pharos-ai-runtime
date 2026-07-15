import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/employees/employee_context.dart';

abstract class Employee {
  String get id;

  Future<Result> execute(EmployeeContext context);
}
