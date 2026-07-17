import 'package:pharos_ai_runtime/employees/employee_definition.dart';
import 'package:pharos_ai_runtime/models/conversation.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/runtime/employee_runtime.dart';
import 'package:pharos_ai_runtime/runtime/runtime_request_builder.dart';
import 'package:pharos_ai_runtime/tooling/tool_definition.dart';
import 'package:pharos_ai_runtime/tooling/tool_output.dart';
import 'package:test/test.dart';

class _FakeRuntimeRequestBuilder extends RuntimeRequestBuilder {
  EmployeeRuntime? capturedEmployee;

  @override
  ModelRequest build(
    EmployeeRuntime employee, {
    List<ToolDefinition> tools = const [],
    List<ToolOutput> toolOutputs = const [],
  }) {
    capturedEmployee = employee;

    return const ModelRequest(conversation: Conversation());
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
