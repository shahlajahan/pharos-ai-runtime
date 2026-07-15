import 'package:pharos_ai_runtime/employees/employee_context.dart';
import 'package:test/test.dart';

void main() {
  test('EmployeeContext stores only employeeId', () {
    const context = EmployeeContext(employeeId: 'employee-1');

    expect(context.employeeId, 'employee-1');
  });
}
