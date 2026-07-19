import 'package:pharos_ai_runtime/workflow/workflow_step_result.dart';

/// The outcome of one Workflow.execute() call: the ordered
/// WorkflowStepResults produced by running each selected PlanStep, one
/// per step, in order. No aggregation, no retry, no resume, no status, no
/// metrics — a pure execution result.
class WorkflowResult {
  const WorkflowResult({required this.stepResults});

  final List<WorkflowStepResult> stepResults;
}
