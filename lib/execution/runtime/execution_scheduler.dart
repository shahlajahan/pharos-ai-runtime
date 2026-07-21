import 'package:pharos_ai_runtime/tasks/models/task.dart';

/// Determines what can run next, purely from Task dependency graphs.
/// Knows nothing about agents, tools, or execution outcomes — only
/// which tasks are already resolved (their dependencies count as
/// satisfied) and which are terminal (will never run again).
class ExecutionScheduler {
  const ExecutionScheduler();

  /// Every Task that is not yet terminal and whose dependencies are all
  /// in [completedTaskIds] — safe to run now, together, as one parallel
  /// round.
  List<Task> executableTasks(
    List<Task> tasks,
    Set<String> completedTaskIds,
    Set<String> terminalTaskIds,
  ) => [
    for (final task in tasks)
      if (!terminalTaskIds.contains(task.id) &&
          task.dependencies.every(
            (dependency) => completedTaskIds.contains(dependency.taskId),
          ))
        task,
  ];

  /// True once every Task has reached a terminal state (completed,
  /// failed, or cancelled/skipped).
  bool isComplete(List<Task> tasks, Set<String> terminalTaskIds) =>
      tasks.every((task) => terminalTaskIds.contains(task.id));

  /// True when tasks remain but none of them are executable — a cycle,
  /// or a dependency on a task that will never complete.
  bool isDeadlocked(
    List<Task> tasks,
    Set<String> completedTaskIds,
    Set<String> terminalTaskIds,
  ) {
    if (isComplete(tasks, terminalTaskIds)) return false;
    return executableTasks(tasks, completedTaskIds, terminalTaskIds).isEmpty;
  }
}
