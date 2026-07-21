import 'package:pharos_ai_runtime/decision/decision.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_context.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_status.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_step.dart';
import 'package:pharos_ai_runtime/workflow/planner/planning_result.dart';
import 'package:pharos_ai_runtime/workflow/planner/workflow_instance.dart';
import 'package:pharos_ai_runtime/workflow/planner/workflow_plan.dart';
import 'package:pharos_ai_runtime/workflow/planner/workflow_planner.dart';
import 'package:pharos_ai_runtime/workflow/registry/workflow_matcher.dart';

/// The default WorkflowPlanner: selects a WorkflowDefinition via
/// WorkflowMatcher, validates its steps (duplicate ids, missing
/// dependencies, circular dependencies, unreachable steps, empty
/// workflows), and — only if valid — produces a WorkflowInstance and an
/// ordered, parallel-grouped WorkflowPlan. Never executes anything.
class DefaultWorkflowPlanner implements WorkflowPlanner {
  const DefaultWorkflowPlanner(this._matcher);

  final WorkflowMatcher _matcher;

  @override
  PlanningResult plan(Decision decision, WorkflowContext context) {
    final definition = _matcher.match(decision);

    if (definition == null) {
      return PlanningResult(
        success: false,
        workflow: null,
        plan: null,
        errors: [
          'No WorkflowDefinition matches decision type '
              '"${decision.type.name}".',
        ],
        warnings: const [],
      );
    }

    final steps = definition.steps;
    final errors = _validate(steps);

    if (errors.isNotEmpty) {
      return PlanningResult(
        success: false,
        workflow: null,
        plan: null,
        errors: errors,
        warnings: const [],
      );
    }

    final groups = _computeGroups(steps);
    final orderedSteps = [for (final group in groups) ...group];
    final now = DateTime.now();

    final instance = WorkflowInstance(
      id: '${definition.id}:${decision.id}',
      definitionId: definition.id,
      status: WorkflowStatus.planned,
      context: context,
      steps: steps,
      createdAt: now,
      plannedAt: now,
    );

    final workflowPlan = WorkflowPlan(
      orderedSteps: orderedSteps,
      parallelGroups: groups,
      blockedSteps: const [],
      warnings: const [],
      estimatedStepCount: steps.length,
    );

    return PlanningResult(
      success: true,
      workflow: instance,
      plan: workflowPlan,
      errors: const [],
      warnings: const [],
    );
  }

  List<String> _validate(List<WorkflowStep> steps) {
    final errors = <String>[];

    if (steps.isEmpty) {
      errors.add('Workflow has no steps.');
      return errors;
    }

    final seenIds = <String>{};
    final duplicateIds = <String>{};
    for (final step in steps) {
      if (!seenIds.add(step.id)) {
        duplicateIds.add(step.id);
      }
    }
    if (duplicateIds.isNotEmpty) {
      errors.add('Duplicate step id(s): ${duplicateIds.join(', ')}.');
    }

    final missingDependencies = <String>{};
    for (final step in steps) {
      for (final dependencyId in step.dependsOn) {
        if (!seenIds.contains(dependencyId)) {
          missingDependencies.add(dependencyId);
        }
      }
    }
    if (missingDependencies.isNotEmpty) {
      errors.add('Missing dependencies: ${missingDependencies.join(', ')}.');
    }

    // Cycle and reachability checks only make sense once the step ids
    // and dependency references are structurally sound.
    if (duplicateIds.isEmpty && missingDependencies.isEmpty) {
      if (_hasCycle(steps)) {
        errors.add('Workflow contains a circular dependency.');
      }

      final unreachable = _unreachableSteps(steps);
      if (unreachable.isNotEmpty) {
        errors.add('Unreachable step(s): ${unreachable.join(', ')}.');
      }
    }

    return errors;
  }

  bool _hasCycle(List<WorkflowStep> steps) {
    final byId = {for (final step in steps) step.id: step};
    final visited = <String>{};
    final inStack = <String>{};

    bool visit(String id) {
      if (inStack.contains(id)) {
        return true;
      }
      if (visited.contains(id)) {
        return false;
      }

      visited.add(id);
      inStack.add(id);
      for (final dependencyId in byId[id]!.dependsOn) {
        if (visit(dependencyId)) {
          return true;
        }
      }
      inStack.remove(id);

      return false;
    }

    return steps.any((step) => visit(step.id));
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

  /// Kahn-style level ordering: each pass collects every step whose
  /// dependencies are already completed, in original step order, so
  /// steps that can run in parallel land in the same group.
  List<List<String>> _computeGroups(List<WorkflowStep> steps) {
    final remaining = {
      for (final step in steps) step.id: step.dependsOn.toSet(),
    };
    final completed = <String>{};
    final groups = <List<String>>[];

    while (completed.length < steps.length) {
      final ready = [
        for (final step in steps)
          if (!completed.contains(step.id) &&
              remaining[step.id]!.every(completed.contains))
            step.id,
      ];

      groups.add(ready);
      completed.addAll(ready);
    }

    return groups;
  }
}
