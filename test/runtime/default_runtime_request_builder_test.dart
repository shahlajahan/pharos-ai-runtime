import 'package:pharos_ai_runtime/employees/employee_definition.dart';
import 'package:pharos_ai_runtime/runtime/default_runtime_request_builder.dart';
import 'package:pharos_ai_runtime/runtime/employee_runtime.dart';
import 'package:test/test.dart';

void main() {
  test(
    'build() returns a ModelRequest with empty systemPrompt and userPrompt',
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

      expect(request.systemPrompt, '');
      expect(request.userPrompt, '');
    },
  );

  test('build() accepts any EmployeeRuntime', () {
    final builder = DefaultRuntimeRequestBuilder();
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'engineering',
        name: 'Engineering Employee',
        role: 'Engineering',
      ),
      knowledge: [],
      prompts: [],
    );

    final request = builder.build(employee);

    expect(request.systemPrompt, '');
    expect(request.userPrompt, '');
  });
}
