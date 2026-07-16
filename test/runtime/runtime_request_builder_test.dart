import 'package:pharos_ai_runtime/employees/employee_definition.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/runtime/employee_runtime.dart';
import 'package:pharos_ai_runtime/runtime/runtime_request_builder.dart';
import 'package:test/test.dart';

class _FakeRuntimeRequestBuilder extends RuntimeRequestBuilder {
  EmployeeRuntime? capturedEmployee;

  @override
  ModelRequest build(EmployeeRuntime employee) {
    capturedEmployee = employee;

    return const ModelRequest(systemPrompt: '', userPrompt: '');
  }
}

void main() {
  test(
    'RuntimeRequestBuilder exposes build(employee) returning a ModelRequest',
    () {
      final builder = _FakeRuntimeRequestBuilder();
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

      expect(request, isA<ModelRequest>());
    },
  );

  test(
    'RuntimeRequestBuilder passes the EmployeeRuntime through unchanged',
    () {
      final builder = _FakeRuntimeRequestBuilder();
      const employee = EmployeeRuntime(
        definition: EmployeeDefinition(
          id: 'marketing',
          name: 'Marketing Employee',
          role: 'Marketing',
        ),
        knowledge: [],
        prompts: [],
      );

      builder.build(employee);

      expect(builder.capturedEmployee, same(employee));
    },
  );
}
