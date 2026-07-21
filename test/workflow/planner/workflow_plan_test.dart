import 'package:pharos_ai_runtime/workflow/planner/workflow_plan.dart';
import 'package:test/test.dart';

void main() {
  test('WorkflowPlan stores every field exactly as constructed', () {
    const plan = WorkflowPlan(
      orderedSteps: ['analyze-market', 'design-campaign'],
      parallelGroups: [
        ['analyze-market'],
        ['design-campaign'],
      ],
      blockedSteps: [],
      warnings: ['none yet'],
      estimatedStepCount: 2,
    );

    expect(plan.orderedSteps, ['analyze-market', 'design-campaign']);
    expect(plan.parallelGroups, [
      ['analyze-market'],
      ['design-campaign'],
    ]);
    expect(plan.blockedSteps, isEmpty);
    expect(plan.warnings, ['none yet']);
    expect(plan.estimatedStepCount, 2);
  });

  test('WorkflowPlan is constructible as a compile-time constant', () {
    const plan = WorkflowPlan(
      orderedSteps: [],
      parallelGroups: [],
      blockedSteps: [],
      warnings: [],
      estimatedStepCount: 0,
    );

    expect(plan, isA<WorkflowPlan>());
  });
}
