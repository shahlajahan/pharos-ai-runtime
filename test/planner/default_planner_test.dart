import 'package:pharos_ai_runtime/planner/default_planner.dart';
import 'package:test/test.dart';

void main() {
  test('plan() returns null for a single-line goal (simple)', () {
    const planner = DefaultPlanner();

    expect(planner.plan('Write a LinkedIn post'), isNull);
  });

  test('plan() returns null for an empty goal', () {
    const planner = DefaultPlanner();

    expect(planner.plan(''), isNull);
  });

  test('plan() returns null for a goal that is only blank lines', () {
    const planner = DefaultPlanner();

    expect(planner.plan('\n   \n'), isNull);
  });

  test('plan() returns a Plan with one PlanStep per non-empty line, in order, '
      'for a multi-line goal (complex)', () {
    const planner = DefaultPlanner();
    const goal = 'Research competitors\nDraft the announcement\nPublish it';

    final plan = planner.plan(goal);

    expect(plan, isNotNull);
    expect(plan!.steps.map((step) => step.description), [
      'Research competitors',
      'Draft the announcement',
      'Publish it',
    ]);
  });

  test('plan() assigns every PlanStep to the "default" Employee, since '
      'DefaultPlanner does not infer Employees', () {
    const planner = DefaultPlanner();
    const goal = 'Research competitors\nDraft the announcement\nPublish it';

    final plan = planner.plan(goal);

    expect(plan, isNotNull);
    expect(
      plan!.steps.every((step) => step.assignedEmployee == 'default'),
      isTrue,
    );
  });

  test('plan() trims whitespace and skips blank lines between steps', () {
    const planner = DefaultPlanner();
    const goal = '  Research competitors  \n\n  Publish it  ';

    final plan = planner.plan(goal);

    expect(plan, isNotNull);
    expect(plan!.steps.map((step) => step.description), [
      'Research competitors',
      'Publish it',
    ]);
  });
}
