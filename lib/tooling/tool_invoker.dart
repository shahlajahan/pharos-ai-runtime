import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/tooling/tool_call.dart';
import 'package:pharos_ai_runtime/tooling/tool_context.dart';
import 'package:pharos_ai_runtime/tooling/tool_registry.dart';

class ToolInvoker {
  const ToolInvoker({required ToolRegistry registry}) : _registry = registry;

  final ToolRegistry _registry;

  Future<Result> invoke(ToolCall toolCall) async {
    final tool = _registry.find(toolCall.name);

    if (tool == null) {
      return Result.failure('Tool "${toolCall.name}" not found.');
    }

    final context = ToolContext(
      toolId: toolCall.name,
      arguments: toolCall.arguments,
    );

    try {
      return await tool.execute(context);
    } catch (e) {
      return Result.failure('Tool "${toolCall.name}" failed: $e');
    }
  }
}
