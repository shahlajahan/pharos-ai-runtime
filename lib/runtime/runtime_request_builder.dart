import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/runtime/employee_runtime.dart';
import 'package:pharos_ai_runtime/tooling/tool_definition.dart';

abstract class RuntimeRequestBuilder {
  ModelRequest build(
    EmployeeRuntime employee, {
    List<ToolDefinition> tools = const [],
  });
}
