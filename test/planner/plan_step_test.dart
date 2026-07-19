import 'package:pharos_ai_runtime/planner/plan_step.dart';
import 'package:test/test.dart';

void main() {
  test('PlanStep stores description and assignedEmployee', () {
    const step = PlanStep(
      description: 'Research competitors',
      assignedEmployee: 'research',
    );

    expect(step.description, 'Research competitors');
    expect(step.assignedEmployee, 'research');
  });
}
