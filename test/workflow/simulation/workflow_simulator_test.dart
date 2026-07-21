import 'package:pharos_ai_runtime/workflow/models/workflow_context.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_status.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_step.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_step_status.dart';
import 'package:pharos_ai_runtime/workflow/planner/workflow_instance.dart';
import 'package:pharos_ai_runtime/workflow/simulation/workflow_simulator.dart';
import 'package:test/test.dart';

WorkflowStep _step(
  String id, {
  List<String> dependsOn = const [],
  WorkflowStepStatus status = WorkflowStepStatus.pending,
  Map<String, Object> metadata = const {},
}) => WorkflowStep(
  id: id,
  title: id,
  description: '',
  status: status,
  dependsOn: dependsOn,
  metadata: metadata,
);

WorkflowInstance _instance(List<WorkflowStep> steps) => WorkflowInstance(
  id: 'launch_campaign:decision-1',
  definitionId: 'launch_campaign',
  status: WorkflowStatus.planned,
  context: const WorkflowContext(company: {}, market: {}, finance: {}),
  steps: steps,
  createdAt: DateTime(2026, 7, 21),
  plannedAt: DateTime(2026, 7, 21),
);

/// The roadmap's own Launch Campaign example.
List<WorkflowStep> _launchCampaignSteps() => [
  _step('analyze-market'),
  _step('analyze-budget'),
  _step('design-campaign', dependsOn: ['analyze-market', 'analyze-budget']),
  _step('generate-images', dependsOn: ['design-campaign']),
  _step('generate-videos', dependsOn: ['design-campaign']),
  _step('publish', dependsOn: ['generate-images', 'generate-videos']),
  _step('measure', dependsOn: ['publish']),
];

void main() {
  test('simulate() produces a successful SimulationResult for a valid '
      'WorkflowInstance', () {
    const simulator = WorkflowSimulator();

    final result = simulator.simulate(_instance(_launchCampaignSteps()));

    expect(result.success, isTrue);
    expect(result.simulation, isNotNull);
    expect(result.simulation!.workflowId, 'launch_campaign:decision-1');
    expect(result.simulation!.estimatedStepCount, 7);
    expect(result.simulation!.blockedSteps, isEmpty);
  });

  test('simulate() groups independent steps for parallel execution, '
      "matching the roadmap's Group 1-5 example exactly", () {
    const simulator = WorkflowSimulator();

    final result = simulator.simulate(_instance(_launchCampaignSteps()));

    expect(result.simulation!.executionGroups, [
      ['analyze-market', 'analyze-budget'],
      ['design-campaign'],
      ['generate-images', 'generate-videos'],
      ['publish'],
      ['measure'],
    ]);
    expect(result.simulation!.estimatedParallelGroups, 5);
  });

  test('simulate() preserves dependency order across groups', () {
    const simulator = WorkflowSimulator();

    final result = simulator.simulate(_instance(_launchCampaignSteps()));

    final groups = result.simulation!.executionGroups;
    int groupOf(String id) => groups.indexWhere((group) => group.contains(id));

    expect(groupOf('analyze-market'), lessThan(groupOf('design-campaign')));
    expect(groupOf('design-campaign'), lessThan(groupOf('generate-images')));
    expect(groupOf('generate-videos'), lessThan(groupOf('publish')));
    expect(groupOf('publish'), lessThan(groupOf('measure')));
  });

  test('simulate() estimates duration as the sum of each group\'s slowest '
      'step, using explicit metadata durations', () {
    const simulator = WorkflowSimulator();
    final steps = [
      _step(
        'analyze-market',
        metadata: const {'estimatedDurationSeconds': 120},
      ),
      _step(
        'generate-images',
        dependsOn: ['analyze-market'],
        metadata: const {'estimatedDurationSeconds': 300},
      ),
      _step(
        'publish',
        dependsOn: ['generate-images'],
        metadata: const {'estimatedDurationSeconds': 30},
      ),
    ];

    final result = simulator.simulate(_instance(steps));

    expect(
      result.simulation!.estimatedDuration,
      const Duration(seconds: 120 + 300 + 30),
    );
  });

  test('simulate() falls back to a default duration for a step with no '
      'explicit estimate', () {
    const simulator = WorkflowSimulator();

    final result = simulator.simulate(_instance([_step('only-step')]));

    expect(result.simulation!.estimatedDuration, const Duration(minutes: 1));
  });

  test('simulate() takes the slower step as the group duration when steps '
      'run in parallel', () {
    const simulator = WorkflowSimulator();
    final steps = [
      _step(
        'generate-images',
        metadata: const {'estimatedDurationSeconds': 300},
      ),
      _step(
        'generate-videos',
        metadata: const {'estimatedDurationSeconds': 600},
      ),
    ];

    final result = simulator.simulate(_instance(steps));

    expect(result.simulation!.estimatedDuration, const Duration(seconds: 600));
  });

  test('simulate() reports a step whose own status is already failed as '
      'blocked, cascading to anything that depends on it', () {
    const simulator = WorkflowSimulator();
    final steps = [
      _step('design-campaign', status: WorkflowStepStatus.failed),
      _step('generate-images', dependsOn: ['design-campaign']),
      _step('publish', dependsOn: ['generate-images']),
    ];

    final result = simulator.simulate(_instance(steps));

    expect(result.success, isTrue);
    expect(result.simulation!.blockedSteps, [
      'design-campaign',
      'generate-images',
      'publish',
    ]);
    expect(
      result.simulation!.executionGroups.expand((group) => group),
      isEmpty,
    );
  });

  test('simulate() reports a skipped step as blocked without blocking '
      'unrelated steps', () {
    const simulator = WorkflowSimulator();
    final steps = [
      _step('analyze-market', status: WorkflowStepStatus.skipped),
      _step('analyze-budget'),
      _step('design-campaign', dependsOn: ['analyze-market', 'analyze-budget']),
    ];

    final result = simulator.simulate(_instance(steps));

    expect(result.simulation!.blockedSteps, [
      'analyze-market',
      'design-campaign',
    ]);
    expect(result.simulation!.executionGroups, [
      ['analyze-budget'],
    ]);
  });

  test('simulate() warns about a missing dependency and blocks the step', () {
    const simulator = WorkflowSimulator();
    final steps = [
      _step('publish', dependsOn: ['does-not-exist']),
    ];

    final result = simulator.simulate(_instance(steps));

    expect(result.success, isTrue);
    expect(
      result.warnings.any((w) => w.contains('Missing dependencies')),
      isTrue,
    );
    expect(result.simulation!.blockedSteps, ['publish']);
  });

  test('simulate() warns about a fully disconnected step', () {
    const simulator = WorkflowSimulator();
    final steps = [
      _step('analyze-market'),
      _step('design-campaign', dependsOn: ['analyze-market']),
      _step('isolated'),
    ];

    final result = simulator.simulate(_instance(steps));

    expect(result.success, isTrue);
    expect(
      result.warnings.any((w) => w.contains('Unreachable step(s): isolated')),
      isTrue,
    );
  });

  test('simulate() never mutates the WorkflowInstance it is given', () {
    const simulator = WorkflowSimulator();
    final instance = _instance(_launchCampaignSteps());
    final stepsBefore = List<WorkflowStep>.of(instance.steps);

    simulator.simulate(instance);

    expect(instance.steps, stepsBefore);
  });

  test('simulate() rejects a workflow with no steps', () {
    const simulator = WorkflowSimulator();

    final result = simulator.simulate(_instance(const []));

    expect(result.success, isFalse);
    expect(result.simulation, isNull);
    expect(result.errors, isNotEmpty);
  });

  test('simulate() is deterministic', () {
    const simulator = WorkflowSimulator();
    final instance = _instance(_launchCampaignSteps());

    final first = simulator.simulate(instance);
    final second = simulator.simulate(instance);

    expect(
      first.simulation!.executionGroups,
      second.simulation!.executionGroups,
    );
    expect(
      first.simulation!.estimatedDuration,
      second.simulation!.estimatedDuration,
    );
  });
}
