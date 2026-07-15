import 'package:pharos_ai_runtime/employees/employee.dart';

class EmployeeRegistry {
  const EmployeeRegistry({Map<String, Employee> employees = const {}})
    : _employees = employees;

  final Map<String, Employee> _employees;

  Employee? find(String id) => _employees[id];
}
