import 'package:pharos_ai_runtime/workflow/simulation/workflow_simulation.dart';
import 'package:test/test.dart';

void main() {
  test('WorkflowSimulation stores every field exactly as constructed', () {
    const simulation = WorkflowSimulation(
      workflowId: 'launch_campaign:decision-1',
      executionGroups: [
        ['analyze-market', 'analyze-budget'],
        ['design-campaign'],
      ],
      estimatedStepCount: 3,
      estimatedParallelGroups: 2,
      estimatedDuration: Duration(minutes: 3),
      warnings: [],
      blockedSteps: [],
    );

    expect(simulation.workflowId, 'launch_campaign:decision-1');
    expect(simulation.executionGroups, [
      ['analyze-market', 'analyze-budget'],
      ['design-campaign'],
    ]);
    expect(simulation.estimatedStepCount, 3);
    expect(simulation.estimatedParallelGroups, 2);
    expect(simulation.estimatedDuration, const Duration(minutes: 3));
    expect(simulation.warnings, isEmpty);
    expect(simulation.blockedSteps, isEmpty);
  });

  test('WorkflowSimulation is constructible as a compile-time constant', () {
    const simulation = WorkflowSimulation(
      workflowId: 'w',
      executionGroups: [],
      estimatedStepCount: 0,
      estimatedParallelGroups: 0,
      estimatedDuration: Duration.zero,
      warnings: [],
      blockedSteps: [],
    );

    expect(simulation, isA<WorkflowSimulation>());
  });
}
