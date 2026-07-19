import 'package:pharos_ai_runtime/execution/execution_decision.dart';
import 'package:pharos_ai_runtime/execution/execution_strategy.dart';
import 'package:pharos_ai_runtime/planner/plan.dart';
import 'package:pharos_ai_runtime/planner/plan_step.dart';
import 'package:test/test.dart';

class _FakeExecutionStrategy implements ExecutionStrategy {
  @override
  ExecutionDecision decide(Plan plan) {
    return ExecutionDecision(steps: plan.steps.take(1).toList());
  }
}

void main() {
  test(
    'ExecutionStrategy exposes decide(Plan) returning ExecutionDecision',
    () {
      const plan = Plan(
        steps: [
          PlanStep(description: 'Research', assignedEmployee: 'default'),
          PlanStep(description: 'Write', assignedEmployee: 'default'),
        ],
      );
      final strategy = _FakeExecutionStrategy();

      final decision = strategy.decide(plan);

      expect(decision.steps, [
        const PlanStep(description: 'Research', assignedEmployee: 'default'),
      ]);
    },
  );
}
