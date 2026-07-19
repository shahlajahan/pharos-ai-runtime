import 'package:pharos_ai_runtime/planner/plan_step.dart';

/// An immutable, ordered sequence of PlanSteps produced by a Planner for a
/// complex goal. Plan carries no execution behavior: it only describes
/// what should happen, never how or when — that belongs to Workflow.
class Plan {
  const Plan({required this.steps});

  final List<PlanStep> steps;
}
