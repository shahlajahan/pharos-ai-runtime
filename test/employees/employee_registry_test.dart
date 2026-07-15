import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/employees/employee.dart';
import 'package:pharos_ai_runtime/employees/employee_context.dart';
import 'package:pharos_ai_runtime/employees/employee_registry.dart';
import 'package:test/test.dart';

class _FakeEmployee extends Employee {
  @override
  String get id => 'fake-employee';

  @override
  Future<Result> execute(EmployeeContext context) async =>
      Result.success('employed');
}

void main() {
  test('EmployeeRegistry defaults to empty and resolves nothing', () {
    const registry = EmployeeRegistry();

    expect(registry.find('fake-employee'), isNull);
  });

  test(
    'EmployeeRegistry resolves an Employee registered via constructor injection',
    () {
      final employee = _FakeEmployee();
      final registry = EmployeeRegistry(
        employees: {employee.id: employee},
      );

      expect(registry.find('fake-employee'), same(employee));
      expect(registry.find('missing'), isNull);
    },
  );
}
