import 'package:pharos_ai_runtime/execution/models/execution_id.dart';
import 'package:pharos_ai_runtime/execution/models/execution_status.dart';
import 'package:pharos_ai_runtime/execution/models/execution_step.dart';
import 'package:pharos_ai_runtime/tools/models/tool_result.dart';

/// One complete workflow execution: the full, detailed state the
/// Execution Engine builds and updates as it runs. Immutable — the
/// Engine produces a new Execution rather than mutating one in place.
class Execution {
  const Execution({
    required this.id,
    required this.workflowId,
    required this.status,
    required this.steps,
    required this.results,
    required this.metrics,
    this.startedAt,
    this.finishedAt,
  });

  final ExecutionId id;
  final String workflowId;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final ExecutionStatus status;
  final List<ExecutionStep> steps;
  final List<ToolResult> results;
  final Map<String, Object> metrics;
}
