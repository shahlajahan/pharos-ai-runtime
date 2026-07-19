import 'package:pharos_ai_runtime/planner/plan.dart';
import 'package:pharos_ai_runtime/planner/plan_step.dart';
import 'package:test/test.dart';

void main() {
  test('Plan stores an ordered list of PlanSteps', () {
    const step1 = PlanStep(
      description: 'Research',
      assignedEmployee: 'default',
    );
    const step2 = PlanStep(description: 'Write', assignedEmployee: 'default');
    const plan = Plan(steps: [step1, step2]);

    expect(plan.steps, [step1, step2]);
  });

  test('Plan can be empty', () {
    const plan = Plan(steps: []);

    expect(plan.steps, isEmpty);
  });
}
