import 'package:pharos_ai_runtime/employees/employee_definition.dart';
import 'package:pharos_ai_runtime/runtime/employee_runtime.dart';
import 'package:pharos_ai_runtime/runtime/employee_session.dart';
import 'package:pharos_ai_runtime/runtime/runtime_context.dart';
import 'package:test/test.dart';

void main() {
  test('EmployeeSession stores a RuntimeContext', () {
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

    const session = EmployeeSession(context: context);

    expect(session.context, same(context));
  });
}
