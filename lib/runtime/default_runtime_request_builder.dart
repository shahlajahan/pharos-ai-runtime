import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/runtime/employee_runtime.dart';
import 'package:pharos_ai_runtime/runtime/runtime_request_builder.dart';
import 'package:pharos_ai_runtime/tooling/tool_definition.dart';

class DefaultRuntimeRequestBuilder extends RuntimeRequestBuilder {
  @override
  ModelRequest build(
    EmployeeRuntime employee, {
    List<ToolDefinition> tools = const [],
  }) {
    final header =
        'You are ${employee.definition.name}.\n'
        'Your role is ${employee.definition.role}.';

    final sections = <String>[header];

    if (employee.prompts.isNotEmpty) {
      sections.add(
        employee.prompts.map((prompt) => prompt.content).join('\n\n'),
      );
    }

    if (employee.knowledge.isNotEmpty) {
      sections.add(
        employee.knowledge.map((knowledge) => knowledge.content).join('\n\n'),
      );
    }

    return ModelRequest(
      systemPrompt: sections.join('\n\n'),
      userPrompt: '',
      tools: tools,
    );
  }
}
