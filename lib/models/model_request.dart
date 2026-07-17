import 'package:pharos_ai_runtime/tooling/tool_definition.dart';

class ModelRequest {
  const ModelRequest({
    required this.systemPrompt,
    required this.userPrompt,
    this.tools = const [],
  });

  final String systemPrompt;
  final String userPrompt;
  final List<ToolDefinition> tools;
}
