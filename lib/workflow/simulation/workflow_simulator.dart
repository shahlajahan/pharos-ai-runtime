import 'package:pharos_ai_runtime/workflow/models/workflow_step.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_step_status.dart';
import 'package:pharos_ai_runtime/workflow/planner/workflow_instance.dart';
import 'package:pharos_ai_runtime/workflow/simulation/simulation_result.dart';
import 'package:pharos_ai_runtime/workflow/simulation/workflow_simulation.dart';

/// The default duration assumed for a step with no explicit estimate in
/// its metadata. An arbitrary but consistent baseline — this is only
/// ever an estimate, never a measurement.
const _defaultStepDuration = Duration(minutes: 1);

/// Metadata key a WorkflowStep may set to override [_defaultStepDuration]
/// with an explicit estimate, in seconds (int or double).
const _estimatedDurationSecondsKey = 'estimatedDurationSeconds';

/// Produces a deterministic execution preview from a planned
/// WorkflowInstance: walks the dependency graph, respects dependencies,
/// groups independent steps for parallel execution, and estimates
/// duration and step count. Never executes anything, never invokes an
/// agent or tool, never contacts an external system, and never mutates
/// the WorkflowInstance it is given. Knows workflows, dependencies, and
/// execution order only.
class WorkflowSimulator {
  const WorkflowSimulator();

  SimulationResult simulate(WorkflowInstance instance) {
    final steps = instance.steps;

    if (steps.isEmpty) {
      return const SimulationResult(
        success: false,
        simulation: null,
        errors: ['Workflow has no steps to simulate.'],
        warnings: [],
      );
    }

    final warnings = <String>[];
    final ids = steps.map((step) => step.id).toSet();

    final missingDependencies = <String>{};
    for (final step in steps) {
      for (final dependencyId in step.dependsOn) {
        if (!ids.contains(dependencyId)) {
          missingDependencies.add(dependencyId);
        }
      }
    }
    if (missingDependencies.isNotEmpty) {
      warnings.add('Missing dependencies: ${missingDependencies.join(', ')}.');
    }

    final unreachable = _unreachableSteps(steps);
    if (unreachable.isNotEmpty) {
      warnings.add('Unreachable step(s): ${unreachable.join(', ')}.');
    }

    final blockedSteps = _blockedSteps(steps, missingDependencies);
    if (blockedSteps.isNotEmpty) {
      warnings.add('Blocked step(s): ${blockedSteps.join(', ')}.');
    }

    final groups = _computeGroups(steps, blockedSteps.toSet());
    final scheduled = {for (final group in groups) ...group};
    final stillBlocked = [
      for (final step in steps)
        if (!scheduled.contains(step.id) && !blockedSteps.contains(step.id))
          step.id,
    ];
    final allBlocked = [...blockedSteps, ...stillBlocked];
    if (stillBlocked.isNotEmpty) {
      warnings.add(
        'Blocked step(s): ${stillBlocked.join(', ')} (dependency cycle).',
      );
    }

    final estimatedDuration = _estimateDuration(steps, groups);

    final simulation = WorkflowSimulation(
      workflowId: instance.id,
      executionGroups: groups,
      estimatedStepCount: steps.length,
      estimatedParallelGroups: groups.length,
      estimatedDuration: estimatedDuration,
      warnings: warnings,
      blockedSteps: allBlocked,
    );

    return SimulationResult(
      success: true,
      simulation: simulation,
      errors: const [],
      warnings: warnings,
    );
  }

  /// A step with no dependencies and nothing depending on it is
  /// disconnected from the rest of the workflow — only meaningful when
  /// the workflow has more than one step.
  List<String> _unreachableSteps(List<WorkflowStep> steps) {
    if (steps.length <= 1) {
      return const [];
    }

    final dependedOn = <String>{for (final step in steps) ...step.dependsOn};

    return [
      for (final step in steps)
        if (step.dependsOn.isEmpty && !dependedOn.contains(step.id)) step.id,
    ];
  }

  /// A step is directly blocked when its own status is already
  /// [WorkflowStepStatus.failed] or [WorkflowStepStatus.skipped], or
  /// when it depends on an id that does not exist at all. Blocking then
  /// cascades to anything that depends on a blocked step, directly or
  /// transitively.
  List<String> _blockedSteps(
    List<WorkflowStep> steps,
    Set<String> missingDependencies,
  ) {
    final blocked = <String>{
      for (final step in steps)
        if (step.status == WorkflowStepStatus.failed ||
            step.status == WorkflowStepStatus.skipped ||
            step.dependsOn.any(missingDependencies.contains))
          step.id,
    };

    var changed = true;
    while (changed) {
      changed = false;
      for (final step in steps) {
        if (blocked.contains(step.id)) {
          continue;
        }
        if (step.dependsOn.any(blocked.contains)) {
          blocked.add(step.id);
          changed = true;
        }
      }
    }

    return [
      for (final step in steps)
        if (blocked.contains(step.id)) step.id,
    ];
  }

  /// Kahn-style level ordering over the non-blocked steps only: each
  /// pass collects every step whose dependencies are already
  /// satisfied, so independent steps land in the same group. If a pass
  /// finds nothing ready while steps remain (an undetected cycle in a
  /// directly-constructed WorkflowInstance), scheduling simply stops —
  /// the caller reports whatever is left over as blocked.
  List<List<String>> _computeGroups(
    List<WorkflowStep> steps,
    Set<String> blocked,
  ) {
    final schedulable = [
      for (final step in steps)
        if (!blocked.contains(step.id)) step,
    ];
    final schedulableIds = schedulable.map((step) => step.id).toSet();
    final remaining = {
      for (final step in schedulable)
        step.id: step.dependsOn.where(schedulableIds.contains).toSet(),
    };
    final completed = <String>{};
    final groups = <List<String>>[];

    while (completed.length < schedulable.length) {
      final ready = [
        for (final step in schedulable)
          if (!completed.contains(step.id) &&
              remaining[step.id]!.every(completed.contains))
            step.id,
      ];

      if (ready.isEmpty) {
        break;
      }

      groups.add(ready);
      completed.addAll(ready);
    }

    return groups;
  }

  /// Total = sum of each group's slowest step: groups run in sequence,
  /// but steps within a group run in parallel.
  Duration _estimateDuration(
    List<WorkflowStep> steps,
    List<List<String>> groups,
  ) {
    final byId = {for (final step in steps) step.id: step};
    var total = Duration.zero;

    for (final group in groups) {
      if (group.isEmpty) {
        continue;
      }

      final groupDuration = group
          .map((id) => _stepDuration(byId[id]!))
          .reduce((a, b) => a > b ? a : b);
      total += groupDuration;
    }

    return total;
  }

  Duration _stepDuration(WorkflowStep step) {
    final estimate = step.metadata[_estimatedDurationSecondsKey];

    if (estimate is int) {
      return Duration(seconds: estimate);
    }
    if (estimate is double) {
      return Duration(milliseconds: (estimate * 1000).round());
    }

    return _defaultStepDuration;
  }
}
