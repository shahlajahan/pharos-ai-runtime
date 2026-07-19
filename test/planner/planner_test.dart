import 'package:pharos_ai_runtime/planner/plan.dart';
import 'package:pharos_ai_runtime/planner/plan_step.dart';
import 'package:pharos_ai_runtime/planner/planner.dart';
import 'package:test/test.dart';

class _FakePlanner implements Planner {
  @override
  Plan? plan(String goal) {
    if (goal == 'simple') {
      return null;
    }

    return const Plan(
      steps: [
        PlanStep(description: 'Do the thing', assignedEmployee: 'default'),
      ],
    );
  }
}

void main() {
  test('Planner exposes plan(String) returning Plan?', () {
    final planner = _FakePlanner();

    expect(planner.plan('simple'), isNull);
    expect(planner.plan('complex')!.steps, hasLength(1));
  });
}
