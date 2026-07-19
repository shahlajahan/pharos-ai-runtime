import 'package:pharos_ai_runtime/execution/execution_decision.dart';
import 'package:pharos_ai_runtime/hq/hq.dart';
import 'package:pharos_ai_runtime/workflow/workflow.dart';
import 'package:pharos_ai_runtime/workflow/workflow_context.dart';
import 'package:pharos_ai_runtime/workflow/workflow_result.dart';
import 'package:pharos_ai_runtime/workflow/workflow_step_result.dart';

/// The first Workflow implementation: executes every selected PlanStep
/// sequentially, one HQ.invoke() call per step, in order. Each step's
/// assignedEmployee decides which Employee is resolved and run — Workflow
/// does not know how Employees are loaded, since HQ already owns that
/// responsibility.
///
/// Workflow owns one WorkflowContext across the whole execute() call,
/// starting empty and growing by one WorkflowStepResult after every step,
/// so later steps' Employees can see earlier steps' outputs. No branching,
/// no retries, no pause, no cancellation, no parallelism.
class DefaultWorkflow implements Workflow {
  DefaultWorkflow({required HQ hq}) : _hq = hq;

  final HQ _hq;

  @override
  Future<WorkflowResult> execute(ExecutionDecision decision) async {
    var context = const WorkflowContext(previousSteps: []);
    final stepResults = <WorkflowStepResult>[];

    for (final step in decision.steps) {
      final result = await _hq.invoke(
        employee: step.assignedEmployee,
        goal: step.description,
        context: context,
      );

      final stepResult = WorkflowStepResult(step: step, result: result);
      stepResults.add(stepResult);

      context = WorkflowContext(
        previousSteps: [...context.previousSteps, stepResult],
      );
    }

    return WorkflowResult(stepResults: stepResults);
  }
}
