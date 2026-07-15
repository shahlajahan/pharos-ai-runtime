import 'package:pharos_ai_runtime/employees/employee_definition.dart';
import 'package:test/test.dart';

void main() {
  test('EmployeeDefinition stores id, name, and role', () {
    const definition = EmployeeDefinition(
      id: 'marketing',
      name: 'Marketing Employee',
      role: 'Marketing',
    );

    expect(definition.id, 'marketing');
    expect(definition.name, 'Marketing Employee');
    expect(definition.role, 'Marketing');
  });
}
