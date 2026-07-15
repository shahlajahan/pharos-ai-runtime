import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/employees/employee.dart';
import 'package:pharos_ai_runtime/employees/employee_context.dart';
import 'package:test/test.dart';

class _FakeEmployee extends Employee {
  @override
  String get id => 'fake-employee';

  @override
  Future<Result> execute(EmployeeContext context) async =>
      Result.success('employed');
}

void main() {
  test('Employee exposes id and execute(context) returning a Result', () async {
    final employee = _FakeEmployee();

    final result = await employee.execute(
      const EmployeeContext(employeeId: 'fake-employee'),
    );

    expect(employee.id, 'fake-employee');
    expect(result.success, isTrue);
    expect(result.message, 'employed');
  });
}
