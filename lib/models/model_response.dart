import 'package:pharos_ai_runtime/tooling/tool_call.dart';

class ModelResponse {
  const ModelResponse({required this.text, this.toolCalls = const []});

  final String text;
  final List<ToolCall> toolCalls;
}
