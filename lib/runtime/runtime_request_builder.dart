import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/runtime/employee_runtime.dart';

abstract class RuntimeRequestBuilder {
  ModelRequest build(EmployeeRuntime employee);
}
