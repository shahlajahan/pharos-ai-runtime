import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/planner/plan_step.dart';
import 'package:pharos_ai_runtime/workflow/workflow_result.dart';
import 'package:pharos_ai_runtime/workflow/workflow_step_result.dart';
import 'package:test/test.dart';

void main() {
  test('WorkflowResult stores an ordered list of WorkflowStepResults', () {
    final stepResult1 = WorkflowStepResult(
      step: const PlanStep(
        description: 'Research',
        assignedEmployee: 'default',
      ),
      result: Result.success('done researching'),
    );
    final stepResult2 = WorkflowStepResult(
      step: const PlanStep(description: 'Write', assignedEmployee: 'default'),
      result: Result.success('done writing'),
    );
    final workflowResult = WorkflowResult(
      stepResults: [stepResult1, stepResult2],
    );

    expect(workflowResult.stepResults, [stepResult1, stepResult2]);
  });

  test('WorkflowResult can be empty', () {
    const workflowResult = WorkflowResult(stepResults: []);

    expect(workflowResult.stepResults, isEmpty);
  });
}
