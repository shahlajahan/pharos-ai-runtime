/// One dependency between Tasks: the owning Task cannot start until the
/// Task identified by [taskId] has completed. A dedicated value object
/// (rather than a bare id) so future compatibility — conditional
/// dependencies, retries, human approval gates — can be added without
/// changing Task's public API.
class TaskDependency {
  const TaskDependency(this.taskId);

  final String taskId;
}
