/// The outcome of running a Workflow — an execution placeholder only.
/// No aggregation logic, no retry, no resume: just the shape a future
/// execution layer will need to fill in.
class WorkflowResult {
  const WorkflowResult({
    required this.success,
    required this.completedSteps,
    required this.failedSteps,
    required this.duration,
    required this.outputs,
  });

  final bool success;

  /// WorkflowStep ids that completed successfully.
  final List<String> completedSteps;

  /// WorkflowStep ids that failed.
  final List<String> failedSteps;

  final Duration duration;
  final Map<String, Object> outputs;
}
