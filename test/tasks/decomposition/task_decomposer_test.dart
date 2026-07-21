import 'package:pharos_ai_runtime/tasks/decomposition/task_decomposer.dart';
import 'package:pharos_ai_runtime/tasks/models/task_status.dart';
import 'package:pharos_ai_runtime/tasks/models/task_type.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_context.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_status.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_step.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_step_status.dart';
import 'package:pharos_ai_runtime/workflow/planner/workflow_instance.dart';
import 'package:test/test.dart';

WorkflowStep _step(
  String id,
  String title, {
  List<String> dependsOn = const [],
  Map<String, Object> metadata = const {},
}) => WorkflowStep(
  id: id,
  title: title,
  description: '',
  status: WorkflowStepStatus.pending,
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

void main() {
  test('decompose() produces exactly one Task per ordinary WorkflowStep', () {
    const decomposer = TaskDecomposer();
    final instance = _instance([
      _step('analyze-market', 'Analyze Market'),
      _step('analyze-budget', 'Analyze Budget'),
    ]);

    final result = decomposer.decompose(instance);

    expect(result.success, isTrue);
    expect(result.tasks, hasLength(2));
    expect(result.tasks.map((t) => t.id), ['analyze-market', 'analyze-budget']);
    expect(result.tasks.every((t) => t.status == TaskStatus.pending), isTrue);
  });

  test('decompose() expands a "Generate Images" step into the roadmap\'s six '
      'sequential tasks, preserving their order', () {
    const decomposer = TaskDecomposer();
    final instance = _instance([
      _step('design-campaign', 'Design Campaign'),
      _step(
        'generate-images',
        'Generate Images',
        dependsOn: ['design-campaign'],
      ),
    ]);

    final result = decomposer.decompose(instance);

    final generateImagesTasks = result.tasks
        .where((t) => t.id.startsWith('generate-images.'))
        .toList();

    expect(generateImagesTasks.map((t) => t.title), [
      'Research Style',
      'Collect References',
      'Generate Prompt',
      'Generate Images',
      'Review Assets',
      'Store Assets',
    ]);
  });

  test('decompose() extracts requiredCapabilities for the "Generate Images" '
      'task, matching the roadmap\'s own example exactly', () {
    const decomposer = TaskDecomposer();
    final instance = _instance([_step('generate-images', 'Generate Images')]);

    final result = decomposer.decompose(instance);

    final generateImages = result.tasks.firstWhere(
      (t) => t.title == 'Generate Images',
    );

    expect(generateImages.requiredCapabilities, [
      'image-generation',
      'creative-design',
    ]);
    expect(generateImages.type, TaskType.generation);
  });

  test('decompose() chains the six "Generate Images" sub-tasks sequentially '
      'by dependency', () {
    const decomposer = TaskDecomposer();
    final instance = _instance([_step('generate-images', 'Generate Images')]);

    final result = decomposer.decompose(instance);
    final tasks = result.tasks;

    expect(tasks[0].dependencies, isEmpty);
    for (var i = 1; i < tasks.length; i++) {
      expect(tasks[i].dependencies.single.taskId, tasks[i - 1].id);
    }
  });

  test('decompose() preserves cross-step dependencies: the first task of a '
      'dependent step depends on the last task of its prerequisite step', () {
    const decomposer = TaskDecomposer();
    final instance = _instance([
      _step('design-campaign', 'Design Campaign'),
      _step(
        'generate-images',
        'Generate Images',
        dependsOn: ['design-campaign'],
      ),
    ]);

    final result = decomposer.decompose(instance);
    final tasks = result.tasks;

    final designCampaignTask = tasks.firstWhere(
      (t) => t.id == 'design-campaign',
    );
    final firstImageTask = tasks.firstWhere(
      (t) => t.id == 'generate-images.research-style',
    );

    expect(firstImageTask.dependencies.single.taskId, designCampaignTask.id);
  });

  test('decompose() preserves a multi-parent dependency (Publish depending '
      'on both Generate Images and Generate Videos)', () {
    const decomposer = TaskDecomposer();
    final instance = _instance([
      _step('generate-images', 'Generate Images'),
      _step('generate-videos', 'Generate Videos'),
      _step(
        'publish',
        'Publish',
        dependsOn: ['generate-images', 'generate-videos'],
      ),
    ]);

    final result = decomposer.decompose(instance);
    final publishTask = result.tasks.firstWhere((t) => t.id == 'publish');

    expect(publishTask.dependencies.map((d) => d.taskId).toSet(), {
      'generate-images.store-assets',
      'generate-videos',
    });
  });

  test('decompose() rejects an empty workflow', () {
    const decomposer = TaskDecomposer();

    final result = decomposer.decompose(_instance(const []));

    expect(result.success, isFalse);
    expect(result.tasks, isEmpty);
    expect(result.errors, contains('Workflow has no steps to decompose.'));
  });

  test('decompose() warns about a missing step dependency', () {
    const decomposer = TaskDecomposer();
    final instance = _instance([
      _step('publish', 'Publish', dependsOn: ['does-not-exist']),
    ]);

    final result = decomposer.decompose(instance);

    expect(result.success, isTrue);
    expect(
      result.warnings.single,
      contains('Missing step dependencies: does-not-exist'),
    );
    // The step is still decomposed — a missing dependency degrades
    // gracefully rather than dropping the step entirely.
    expect(result.tasks, hasLength(1));
    expect(result.tasks.single.dependencies, isEmpty);
  });

  test("decompose() reads a step's estimatedDurationSeconds metadata for an "
      'ordinary (non-expanded) task', () {
    const decomposer = TaskDecomposer();
    final instance = _instance([
      _step(
        'analyze-market',
        'Analyze Market',
        metadata: const {'estimatedDurationSeconds': 120},
      ),
    ]);

    final result = decomposer.decompose(instance);

    expect(result.tasks.single.estimatedDuration, const Duration(seconds: 120));
  });

  test(
    'decompose() falls back to a default duration with no explicit estimate',
    () {
      const decomposer = TaskDecomposer();
      final instance = _instance([_step('analyze-market', 'Analyze Market')]);

      final result = decomposer.decompose(instance);

      expect(result.tasks.single.estimatedDuration, const Duration(minutes: 1));
    },
  );

  test('decompose() is deterministic', () {
    const decomposer = TaskDecomposer();
    final instance = _instance([
      _step('design-campaign', 'Design Campaign'),
      _step(
        'generate-images',
        'Generate Images',
        dependsOn: ['design-campaign'],
      ),
    ]);

    final first = decomposer.decompose(instance);
    final second = decomposer.decompose(instance);

    expect(
      first.tasks.map((t) => t.id).toList(),
      second.tasks.map((t) => t.id).toList(),
    );
  });
}
