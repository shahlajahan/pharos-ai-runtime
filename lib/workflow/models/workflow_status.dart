/// A Workflow's lifecycle state. Deliberately has no "draft" — a
/// Workflow is either planned or executable.
enum WorkflowStatus {
  planned,
  ready,
  running,
  paused,
  completed,
  failed,
  cancelled,
}
