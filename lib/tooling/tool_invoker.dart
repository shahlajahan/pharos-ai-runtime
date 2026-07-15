import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/tooling/tool_context.dart';
import 'package:pharos_ai_runtime/tooling/tool_registry.dart';

class ToolInvoker {
  const ToolInvoker({required ToolRegistry registry}) : _registry = registry;

  final ToolRegistry _registry;

  Future<Result> invoke(String toolId) async {
    final tool = _registry.find(toolId);

    if (tool == null) {
      return Result.failure('Tool "$toolId" not found.');
    }

    final context = ToolContext(toolId: toolId);

    try {
      return await tool.execute(context);
    } catch (e) {
      return Result.failure('Tool "$toolId" failed: $e');
    }
  }
}
