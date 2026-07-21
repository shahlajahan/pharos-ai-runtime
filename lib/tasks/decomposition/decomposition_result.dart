import 'package:pharos_ai_runtime/tasks/models/task.dart';

/// The outcome of one TaskDecomposer.decompose() call. [tasks] stays
/// empty whenever [success] is false — an empty Workflow never
/// produces tasks.
class DecompositionResult {
  const DecompositionResult({
    required this.success,
    required this.tasks,
    required this.warnings,
    required this.errors,
  });

  final bool success;
  final List<Task> tasks;
  final List<String> warnings;
  final List<String> errors;
}
