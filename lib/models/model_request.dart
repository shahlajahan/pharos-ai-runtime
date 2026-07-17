import 'package:pharos_ai_runtime/tooling/tool_definition.dart';
import 'package:pharos_ai_runtime/tooling/tool_output.dart';

class ModelRequest {
  const ModelRequest({
    required this.systemPrompt,
    required this.userPrompt,
    this.tools = const [],
    this.toolOutputs = const [],
  });

  final String systemPrompt;
  final String userPrompt;
  final List<ToolDefinition> tools;
  final List<ToolOutput> toolOutputs;
}
