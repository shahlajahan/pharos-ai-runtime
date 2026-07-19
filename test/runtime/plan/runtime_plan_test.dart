import 'package:pharos_ai_runtime/runtime/plan/plan.dart';
import 'package:pharos_ai_runtime/runtime/plan/runtime_plan.dart';
import 'package:test/test.dart';

void main() {
  test('RuntimePlan stores id and title', () {
    const plan = RuntimePlan(id: 'p1', title: 'Ship the release');

    expect(plan.id, 'p1');
    expect(plan.title, 'Ship the release');
    expect(plan, isA<Plan>());
  });
}
