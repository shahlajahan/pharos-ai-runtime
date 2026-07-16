import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/models/model_response.dart';
import 'package:pharos_ai_runtime/runtime/employee_response_handler.dart';
import 'package:pharos_ai_runtime/runtime/employee_runtime.dart';

class DefaultEmployeeResponseHandler extends EmployeeResponseHandler {
  @override
  Future<Result> handle(
    EmployeeRuntime employee,
    ModelResponse response,
  ) async {
    return Result.success(response.text);
  }
}
