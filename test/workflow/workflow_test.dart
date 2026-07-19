import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/execution/execution_decision.dart';
import 'package:pharos_ai_runtime/planner/plan_step.dart';
import 'package:pharos_ai_runtime/workflow/workflow.dart';
import 'package:pharos_ai_runtime/workflow/workflow_result.dart';
import 'package:pharos_ai_runtime/workflow/workflow_step_result.dart';
import 'package:test/test.dart';

class _FakeWorkflow implements Workflow {
  @override
  Future<WorkflowResult> execute(ExecutionDecision decision) async {
    return WorkflowResult(
      stepResults: [
        for (final step in decision.steps)
          WorkflowStepResult(step: step, result: Result.success('handled')),
      ],
    );
  }
}

void main() {
  test(
    'Workflow exposes execute(ExecutionDecision) returning WorkflowResult',
    () async {
      const decision = ExecutionDecision(
        steps: [
          PlanStep(description: 'Research', assignedEmployee: 'default'),
          PlanStep(description: 'Write', assignedEmployee: 'default'),
        ],
      );
      final workflow = _FakeWorkflow();

      final result = await workflow.execute(decision);

      expect(result.stepResults, hasLength(2));
      expect(result.stepResults.map((r) => r.step.description), [
        'Research',
        'Write',
      ]);
    },
  );
}
