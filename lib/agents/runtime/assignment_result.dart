import 'package:pharos_ai_runtime/agents/models/task_assignment.dart';

/// The outcome of one AgentRuntime.assign() call.
class AssignmentResult {
  const AssignmentResult({
    required this.assignments,
    required this.unassignedTasks,
    required this.warnings,
    required this.errors,
  });

  final List<TaskAssignment> assignments;

  /// Ids of tasks for which no eligible agent could be found.
  final List<String> unassignedTasks;

  final List<String> warnings;
  final List<String> errors;
}
