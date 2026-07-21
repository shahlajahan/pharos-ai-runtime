/// One occurrence in an Execution's lifecycle, mirroring the roadmap's
/// Event Flow (Execution Started → Task Started → Tool Invoked → Tool
/// Finished → Task Completed → Workflow Completed → Execution
/// Finished), plus the minimal additions needed to observe failure
/// handling: taskFailed, taskRetried, executionPaused,
/// executionCancelled.
enum ExecutionEventType {
  executionStarted,
  taskStarted,
  toolInvoked,
  toolFinished,
  taskCompleted,
  taskFailed,
  taskRetried,
  executionPaused,
  executionCancelled,
  workflowCompleted,
  executionFinished,
}

/// One immutable record of something that happened during an Execution.
class ExecutionEvent {
  const ExecutionEvent({
    required this.type,
    required this.timestamp,
    required this.message,
    this.taskId,
  });

  final ExecutionEventType type;
  final DateTime timestamp;

  /// The Task this event concerns, or null for execution-wide events.
  final String? taskId;

  final String message;
}
