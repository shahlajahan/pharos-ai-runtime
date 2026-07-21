/// The complete, deterministic execution preview for one planned
/// Workflow — what would happen if it were executed, without executing
/// it. No timers, no agents, no tools, no external systems.
class WorkflowSimulation {
  const WorkflowSimulation({
    required this.workflowId,
    required this.executionGroups,
    required this.estimatedStepCount,
    required this.estimatedParallelGroups,
    required this.estimatedDuration,
    required this.warnings,
    required this.blockedSteps,
  });

  /// The [WorkflowInstance.id] this simulation was produced from.
  final String workflowId;

  /// Ordered execution stages: step ids sharing a group have no
  /// dependency on each other and could run in parallel; groups
  /// themselves run in order.
  final List<List<String>> executionGroups;

  final int estimatedStepCount;
  final int estimatedParallelGroups;

  /// Sum of each group's slowest step — the only way parallel groups
  /// combine into a single estimate. Estimation only: no timers, no
  /// execution.
  final Duration estimatedDuration;

  final List<String> warnings;

  /// Step ids that could not be scheduled (for example because their
  /// own status is already failed/skipped, or because they depend,
  /// directly or transitively, on such a step).
  final List<String> blockedSteps;
}
