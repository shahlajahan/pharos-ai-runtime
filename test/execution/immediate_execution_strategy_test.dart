import 'package:pharos_ai_runtime/execution/immediate_execution_strategy.dart';
import 'package:pharos_ai_runtime/planner/plan.dart';
import 'package:pharos_ai_runtime/planner/plan_step.dart';
import 'package:test/test.dart';

void main() {
  test('decide() returns an ExecutionDecision containing all PlanSteps in '
      'their original order', () {
    const step1 = PlanStep(
      description: 'Research competitors',
      assignedEmployee: 'default',
    );
    const step2 = PlanStep(
      description: 'Draft the announcement',
      assignedEmployee: 'default',
    );
    const step3 = PlanStep(
      description: 'Publish it',
      assignedEmployee: 'default',
    );
    const plan = Plan(steps: [step1, step2, step3]);
    const strategy = ImmediateExecutionStrategy();

    final decision = strategy.decide(plan);

    expect(decision.steps, [step1, step2, step3]);
  });

  test('decide() returns an empty ExecutionDecision for an empty Plan', () {
    const plan = Plan(steps: []);
    const strategy = ImmediateExecutionStrategy();

    final decision = strategy.decide(plan);

    expect(decision.steps, isEmpty);
  });

  test('decide() selects a single-step Plan unchanged', () {
    const step = PlanStep(
      description: 'Only step',
      assignedEmployee: 'default',
    );
    const plan = Plan(steps: [step]);
    const strategy = ImmediateExecutionStrategy();

    final decision = strategy.decide(plan);

    expect(decision.steps, [step]);
  });
}
