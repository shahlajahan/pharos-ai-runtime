import 'package:pharos_ai_runtime/tasks/models/task_dependency.dart';
import 'package:pharos_ai_runtime/tasks/models/task_priority.dart';
import 'package:pharos_ai_runtime/tasks/models/task_status.dart';
import 'package:pharos_ai_runtime/tasks/models/task_type.dart';

/// The smallest executable unit of work — what a Workflow Step
/// decomposes into. Immutable value object: no execution logic, and no
/// knowledge of which agent or tool will eventually perform it (that is
/// exactly what [requiredCapabilities] defers to a future Agent
/// Runtime).
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.status,
    required this.dependencies,
    required this.requiredCapabilities,
    required this.estimatedDuration,
    required this.metadata,
  });

  final String id;
  final String title;
  final String description;
  final TaskType type;
  final TaskPriority priority;
  final TaskStatus status;

  /// Other Tasks that must complete before this one may run.
  final List<TaskDependency> dependencies;

  /// The capabilities required to execute this task (for example
  /// "image-generation"). The task never knows which agent or tool
  /// actually provides them.
  final List<String> requiredCapabilities;

  final Duration estimatedDuration;
  final Map<String, Object> metadata;
}
