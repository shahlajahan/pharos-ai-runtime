import 'package:pharos_ai_runtime/agents/models/agent_id.dart';
import 'package:pharos_ai_runtime/execution/models/execution_status.dart';
import 'package:pharos_ai_runtime/tools/models/tool_id.dart';
import 'package:pharos_ai_runtime/tools/models/tool_result.dart';

/// A record of one executed Task within an Execution. Immutable — the
/// Execution Engine builds a new ExecutionStep for each state
/// transition rather than mutating one in place.
///
/// [toolUsed] stays null in this milestone: ToolRuntime.invoke() (see
/// `lib/tools/runtime/tool_runtime.dart`) does not yet return which
/// Tool it selected as a separate field, only a normalized ToolResult.
class ExecutionStep {
  const ExecutionStep({
    required this.taskId,
    required this.status,
    this.assignedAgent,
    this.toolUsed,
    this.startedAt,
    this.finishedAt,
    this.result,
  });

  final String taskId;
  final ExecutionStatus status;
  final AgentId? assignedAgent;
  final ToolId? toolUsed;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final ToolResult? result;
}
