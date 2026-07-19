import 'package:pharos_ai_runtime/runtime/plan/runtime_plan.dart';
import 'package:pharos_ai_runtime/runtime/planning/planning_result.dart';
import 'package:test/test.dart';

void main() {
  test('PlanningResult stores Plan', () {
    const plan = RuntimePlan(id: 'p1', title: 'Ship the release');
    const result = PlanningResult(plan: plan);

    expect(result.plan, same(plan));
  });
}
