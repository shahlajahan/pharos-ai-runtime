/// The Execution Report: the normalized summary an Execution Engine run
/// produces, independent of how many steps or retries occurred.
class ExecutionResult {
  const ExecutionResult({
    required this.success,
    required this.failedTasks,
    required this.completedTasks,
    required this.duration,
    required this.artifacts,
    required this.warnings,
    required this.errors,
    required this.metrics,
  });

  final bool success;
  final List<String> failedTasks;
  final List<String> completedTasks;
  final Duration duration;
  final List<String> artifacts;
  final List<String> warnings;
  final List<String> errors;
  final Map<String, Object> metrics;
}
