import 'package:pharos_ai_runtime/employees/employee_definition.dart';
import 'package:pharos_ai_runtime/models/model_response.dart';
import 'package:pharos_ai_runtime/runtime/default_employee_response_handler.dart';
import 'package:pharos_ai_runtime/runtime/employee_runtime.dart';
import 'package:test/test.dart';

void main() {
  test('handle() wraps response.text into a successful Result', () async {
    final handler = DefaultEmployeeResponseHandler();
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [],
      prompts: [],
    );
    const response = ModelResponse(text: 'response text');

    final result = await handler.handle(employee, response);

    expect(result.message, 'response text');
    expect(result.success, isTrue);
  });

  test('handle() accepts any EmployeeRuntime without inspecting it', () async {
    final handler = DefaultEmployeeResponseHandler();
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'engineering',
        name: 'Engineering Employee',
        role: 'Engineering',
      ),
      knowledge: [],
      prompts: [],
    );
    const response = ModelResponse(text: 'another response');

    final result = await handler.handle(employee, response);

    expect(result.message, 'another response');
    expect(result.success, isTrue);
  });
}
