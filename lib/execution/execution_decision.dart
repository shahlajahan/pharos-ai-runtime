import 'package:pharos_ai_runtime/planner/plan_step.dart';

/// An immutable, ordered sequence of PlanSteps selected by an
/// ExecutionStrategy for a Plan. ExecutionDecision carries no execution
/// behavior itself: it only describes which steps were selected, and in
/// what order — never how or when they run.
class ExecutionDecision {
  const ExecutionDecision({required this.steps});

  final List<PlanStep> steps;
}
