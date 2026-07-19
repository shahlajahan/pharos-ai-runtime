import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/planner/plan_step.dart';
import 'package:pharos_ai_runtime/workflow/workflow_step_result.dart';
import 'package:test/test.dart';

void main() {
  test('WorkflowStepResult stores the PlanStep and its Result', () {
    const step = PlanStep(
      description: 'Research competitors',
      assignedEmployee: 'default',
    );
    final result = Result.success('done');
    final stepResult = WorkflowStepResult(step: step, result: result);

    expect(stepResult.step, same(step));
    expect(stepResult.result, same(result));
  });
}
