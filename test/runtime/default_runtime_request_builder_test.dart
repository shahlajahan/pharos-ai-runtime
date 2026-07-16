import 'package:pharos_ai_runtime/employees/employee_definition.dart';
import 'package:pharos_ai_runtime/runtime/default_runtime_request_builder.dart';
import 'package:pharos_ai_runtime/runtime/employee_runtime.dart';
import 'package:test/test.dart';

void main() {
  test(
    'build() returns a systemPrompt containing the employee name and role',
    () {
      final builder = DefaultRuntimeRequestBuilder();
      const employee = EmployeeRuntime(
        definition: EmployeeDefinition(
          id: 'marketing',
          name: 'Marketing Employee',
          role: 'Marketing',
        ),
        knowledge: [],
        prompts: [],
      );

      final request = builder.build(employee);

      expect(request.systemPrompt, contains('Marketing Employee'));
      expect(request.systemPrompt, contains('Marketing'));
    },
  );

  test('build() returns an empty userPrompt', () {
    final builder = DefaultRuntimeRequestBuilder();
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [],
      prompts: [],
    );

    final request = builder.build(employee);

    expect(request.userPrompt, '');
  });

  test('build() works for different employees', () {
    final builder = DefaultRuntimeRequestBuilder();
    const engineering = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'engineering',
        name: 'Engineering Employee',
        role: 'Engineering',
      ),
      knowledge: [],
      prompts: [],
    );

    final request = builder.build(engineering);

    expect(request.systemPrompt, contains('Engineering Employee'));
    expect(request.systemPrompt, contains('Engineering'));
    expect(request.userPrompt, '');
  });
}
