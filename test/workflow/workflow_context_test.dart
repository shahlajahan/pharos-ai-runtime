import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/planner/plan_step.dart';
import 'package:pharos_ai_runtime/workflow/workflow_context.dart';
import 'package:pharos_ai_runtime/workflow/workflow_step_result.dart';
import 'package:test/test.dart';

void main() {
  test('WorkflowContext stores an ordered list of previousSteps', () {
    final stepResult1 = WorkflowStepResult(
      step: const PlanStep(
        description: 'Research',
        assignedEmployee: 'research',
      ),
      result: Result.success('research done'),
    );
    final stepResult2 = WorkflowStepResult(
      step: const PlanStep(description: 'Write', assignedEmployee: 'marketing'),
      result: Result.success('copy written'),
    );
    final context = WorkflowContext(previousSteps: [stepResult1, stepResult2]);

    expect(context.previousSteps, [stepResult1, stepResult2]);
  });

  test('WorkflowContext can start empty', () {
    const context = WorkflowContext(previousSteps: []);

    expect(context.previousSteps, isEmpty);
  });
}
