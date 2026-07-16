import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/models/model_response.dart';
import 'package:pharos_ai_runtime/runtime/employee_runtime.dart';

abstract class EmployeeResponseHandler {
  Future<Result> handle(EmployeeRuntime employee, ModelResponse response);
}
