import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/planner/plan_step.dart';

/// The outcome of executing one PlanStep: the step itself, paired with the
/// Result Runtime produced for it. Nothing else.
class WorkflowStepResult {
  const WorkflowStepResult({required this.step, required this.result});

  final PlanStep step;
  final Result result;
}
