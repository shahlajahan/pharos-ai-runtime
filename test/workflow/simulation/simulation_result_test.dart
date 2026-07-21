import 'package:pharos_ai_runtime/workflow/simulation/simulation_result.dart';
import 'package:pharos_ai_runtime/workflow/simulation/workflow_simulation.dart';
import 'package:test/test.dart';

void main() {
  test('a successful SimulationResult carries a WorkflowSimulation', () {
    const result = SimulationResult(
      success: true,
      simulation: WorkflowSimulation(
        workflowId: 'w',
        executionGroups: [],
        estimatedStepCount: 0,
        estimatedParallelGroups: 0,
        estimatedDuration: Duration.zero,
        warnings: [],
        blockedSteps: [],
      ),
      errors: [],
      warnings: [],
    );

    expect(result.success, isTrue);
    expect(result.simulation, isNotNull);
    expect(result.errors, isEmpty);
  });

  test('success can be true even when warnings and blockedSteps are '
      'non-empty — reporting a blocked preview is not a failure', () {
    const result = SimulationResult(
      success: true,
      simulation: WorkflowSimulation(
        workflowId: 'w',
        executionGroups: [],
        estimatedStepCount: 1,
        estimatedParallelGroups: 0,
        estimatedDuration: Duration.zero,
        warnings: ['Blocked step(s): publish.'],
        blockedSteps: ['publish'],
      ),
      errors: [],
      warnings: ['Blocked step(s): publish.'],
    );

    expect(result.success, isTrue);
    expect(result.simulation!.blockedSteps, ['publish']);
  });

  test('a failed SimulationResult never carries a WorkflowSimulation', () {
    const result = SimulationResult(
      success: false,
      simulation: null,
      errors: ['Workflow has no steps to simulate.'],
      warnings: [],
    );

    expect(result.success, isFalse);
    expect(result.simulation, isNull);
  });
}
