/// The final, deterministic execution order for a planned Workflow.
/// Contains no runtime state — just the shape a future execution layer
/// will follow. Nothing here executes anything.
class WorkflowPlan {
  const WorkflowPlan({
    required this.orderedSteps,
    required this.parallelGroups,
    required this.blockedSteps,
    required this.warnings,
    required this.estimatedStepCount,
  });

  /// Every step id in a valid dependency order.
  final List<String> orderedSteps;

  /// Steps grouped by execution stage: steps within one group share no
  /// dependency on each other and may run in parallel; groups
  /// themselves run in the given order.
  final List<List<String>> parallelGroups;

  /// Step ids that could not be scheduled.
  final List<String> blockedSteps;

  final List<String> warnings;
  final int estimatedStepCount;
}
