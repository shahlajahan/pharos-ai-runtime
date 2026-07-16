import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/runtime/employee_runtime.dart';
import 'package:pharos_ai_runtime/runtime/runtime_request_builder.dart';

class DefaultRuntimeRequestBuilder extends RuntimeRequestBuilder {
  @override
  ModelRequest build(EmployeeRuntime employee) {
    final systemPrompt =
        'You are ${employee.definition.name}.\n'
        'Your role is ${employee.definition.role}.';

    return ModelRequest(systemPrompt: systemPrompt, userPrompt: '');
  }
}
