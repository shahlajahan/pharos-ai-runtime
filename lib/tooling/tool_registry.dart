import 'package:pharos_ai_runtime/tooling/tool.dart';
import 'package:pharos_ai_runtime/tooling/tool_definition.dart';

class ToolRegistry {
  const ToolRegistry({
    this.tools = const {},
    Map<String, ToolDefinition> definitions = const {},
  }) : _definitions = definitions;

  final Map<String, Tool> tools;
  final Map<String, ToolDefinition> _definitions;

  Tool? find(String id) => tools[id];

  List<ToolDefinition> definitions() => _definitions.values.toList();
}
