import 'package:pharos_ai_runtime/models/conversation.dart';
import 'package:pharos_ai_runtime/tooling/tool_definition.dart';
import 'package:pharos_ai_runtime/tooling/tool_output.dart';

class ModelRequest {
  const ModelRequest({
    required this.conversation,
    this.tools = const [],
    this.toolOutputs = const [],
  });

  final Conversation conversation;
  final List<ToolDefinition> tools;
  final List<ToolOutput> toolOutputs;
}
