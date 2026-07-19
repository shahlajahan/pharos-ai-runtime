import 'package:pharos_ai_runtime/runtime/intent/runtime_intent.dart';
import 'package:pharos_ai_runtime/runtime/plan/runtime_plan.dart';
import 'package:pharos_ai_runtime/runtime/planning/default_runtime_planner.dart';
import 'package:pharos_ai_runtime/runtime/planning/planning_request.dart';
import 'package:test/test.dart';

class _FakeRuntimeIntent implements RuntimeIntent {
  _FakeRuntimeIntent(this.id, this.title);

  @override
  final String id;

  @override
  final String title;
}

void main() {
  test('DefaultRuntimePlanner has a dependency-free const constructor', () {
    const planner = DefaultRuntimePlanner();

    expect(planner, isNotNull);
  });

  test('plan() returns a PlanningResult carrying a RuntimePlan with the '
      "intent's id and title", () async {
    const planner = DefaultRuntimePlanner();
    final request = PlanningRequest(
      intent: _FakeRuntimeIntent('i1', 'Release version 2.0'),
    );

    final result = await planner.plan(request);

    expect(result.plan, isA<RuntimePlan>());
    expect(result.plan.id, 'i1');
    expect(result.plan.title, 'Release version 2.0');
  });
}
