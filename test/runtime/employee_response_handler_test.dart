import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/employees/employee_definition.dart';
import 'package:pharos_ai_runtime/models/model_response.dart';
import 'package:pharos_ai_runtime/runtime/employee_response_handler.dart';
import 'package:pharos_ai_runtime/runtime/employee_runtime.dart';
import 'package:test/test.dart';

class _FakeEmployeeResponseHandler extends EmployeeResponseHandler {
  EmployeeRuntime? capturedEmployee;
  ModelResponse? capturedResponse;

  @override
  Future<Result> handle(
    EmployeeRuntime employee,
    ModelResponse response,
  ) async {
    capturedEmployee = employee;
    capturedResponse = response;

    return Result.success('handled');
  }
}

void main() {
  test(
    'EmployeeResponseHandler passes the EmployeeRuntime through unchanged',
    () async {
      final handler = _FakeEmployeeResponseHandler();
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

      await handler.handle(employee, response);

      expect(handler.capturedEmployee, same(employee));
    },
  );

  test(
    'EmployeeResponseHandler passes the ModelResponse through unchanged',
    () async {
      final handler = _FakeEmployeeResponseHandler();
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

      await handler.handle(employee, response);

      expect(handler.capturedResponse, same(response));
    },
  );

  test('EmployeeResponseHandler exposes handle() returning a Result', () async {
    final handler = _FakeEmployeeResponseHandler();
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

    expect(result.success, isTrue);
    expect(result.message, 'handled');
  });
}
