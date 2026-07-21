import 'package:pharos_ai_runtime/tools/models/tool.dart';
import 'package:pharos_ai_runtime/tools/models/tool_id.dart';

/// Stores every registered Tool. Contains tools only — no execution,
/// no knowledge of requests or selection policy. Mutable only via
/// [register] and [remove].
///
/// Distinct from the unrelated `ToolRegistry` in
/// `lib/tooling/tool_registry.dart` (the Runtime's execution-pipeline
/// tool-calling registry, still used by `ToolInvoker`). The two coexist
/// under different import paths.
class ToolRegistry {
  ToolRegistry();

  final Map<String, Tool> _tools = {};

  void register(Tool tool) {
    if (_tools.containsKey(tool.id.value)) {
      throw ArgumentError.value(
        tool.id.value,
        'tool.id',
        'A Tool with this id is already registered.',
      );
    }
    _tools[tool.id.value] = tool;
  }

  void remove(ToolId id) => _tools.remove(id.value);

  Tool? find(ToolId id) => _tools[id.value];

  List<Tool> list() => _tools.values.toList();
}
