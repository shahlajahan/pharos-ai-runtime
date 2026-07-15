import 'package:pharos_ai_runtime/employees/employee_definition.dart';
import 'package:pharos_ai_runtime/runtime/employee_runtime.dart';
import 'package:pharos_ai_runtime/runtime/runtime_context.dart';
import 'package:test/test.dart';

void main() {
  test('RuntimeContext stores an EmployeeRuntime', () {
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [],
      prompts: [],
    );

    const context = RuntimeContext(employee: employee);

    expect(context.employee, same(employee));
  });
}
