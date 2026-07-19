import 'package:pharos_ai_runtime/planner/plan.dart';
import 'package:pharos_ai_runtime/planner/plan_step.dart';
import 'package:pharos_ai_runtime/planner/planner.dart';

/// Deterministic Planner: a goal is complex when it spans more than one
/// non-empty line, and each non-empty line becomes one PlanStep, in
/// order. A goal that fits on a single line (or has no non-empty lines at
/// all) is simple, so no Plan is needed.
///
/// Every PlanStep is assigned to [defaultEmployee]: DefaultPlanner does not
/// infer which Employee should run a step — that belongs to future AI
/// planners.
class DefaultPlanner implements Planner {
  const DefaultPlanner();

  static const String defaultEmployee = 'default';

  @override
  Plan? plan(String goal) {
    final lines = goal
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.length <= 1) {
      return null;
    }

    return Plan(
      steps: [
        for (final line in lines)
          PlanStep(description: line, assignedEmployee: defaultEmployee),
      ],
    );
  }
}
