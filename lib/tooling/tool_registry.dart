import 'package:pharos_ai_runtime/tooling/tool.dart';

class ToolRegistry {
  const ToolRegistry({Map<String, Tool> tools = const {}}) : _tools = tools;

  final Map<String, Tool> _tools;

  Tool? find(String id) => _tools[id];
}
