import 'package:pharos_ai_runtime/workflow/workflow_step_result.dart';

/// The accumulated outputs of previously executed PlanSteps within one
/// Workflow.execute() call. Immutable: Workflow builds a new
/// WorkflowContext after every step rather than mutating one in place.
class WorkflowContext {
  const WorkflowContext({required this.previousSteps});

  final List<WorkflowStepResult> previousSteps;
}
