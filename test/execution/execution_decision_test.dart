import 'package:pharos_ai_runtime/execution/execution_decision.dart';
import 'package:pharos_ai_runtime/planner/plan_step.dart';
import 'package:test/test.dart';

void main() {
  test('ExecutionDecision stores an ordered list of PlanSteps', () {
    const step1 = PlanStep(
      description: 'Research',
      assignedEmployee: 'default',
    );
    const step2 = PlanStep(description: 'Write', assignedEmployee: 'default');
    const decision = ExecutionDecision(steps: [step1, step2]);

    expect(decision.steps, [step1, step2]);
  });

  test('ExecutionDecision can be empty', () {
    const decision = ExecutionDecision(steps: []);

    expect(decision.steps, isEmpty);
  });
}
