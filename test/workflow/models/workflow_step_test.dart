import 'package:pharos_ai_runtime/workflow/models/workflow_step.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_step_status.dart';
import 'package:test/test.dart';

void main() {
  test('WorkflowStep stores every field exactly as constructed', () {
    const step = WorkflowStep(
      id: 'generate-images',
      title: 'Generate Images',
      description: 'Generate campaign images.',
      status: WorkflowStepStatus.pending,
      dependsOn: ['design-campaign'],
      metadata: {'model': 'pharos-image-v1'},
    );

    expect(step.id, 'generate-images');
    expect(step.title, 'Generate Images');
    expect(step.description, 'Generate campaign images.');
    expect(step.status, WorkflowStepStatus.pending);
    expect(step.dependsOn, ['design-campaign']);
    expect(step.metadata, {'model': 'pharos-image-v1'});
  });

  test('WorkflowStep is constructible as a compile-time constant, proving '
      'immutability', () {
    const step = WorkflowStep(
      id: 'publish',
      title: 'Publish',
      description: 'Publish the campaign.',
      status: WorkflowStepStatus.pending,
      dependsOn: [],
      metadata: {},
    );

    expect(step, isA<WorkflowStep>());
  });

  test('WorkflowStep can express a chain of dependencies by id, matching the '
      "roadmap's Launch Campaign example", () {
    const analyzeMarket = WorkflowStep(
      id: 'analyze-market',
      title: 'Analyze Market',
      description: '',
      status: WorkflowStepStatus.pending,
      dependsOn: [],
      metadata: {},
    );
    const designCampaign = WorkflowStep(
      id: 'design-campaign',
      title: 'Design Campaign',
      description: '',
      status: WorkflowStepStatus.pending,
      dependsOn: ['analyze-market'],
      metadata: {},
    );
    const generateImages = WorkflowStep(
      id: 'generate-images',
      title: 'Generate Images',
      description: '',
      status: WorkflowStepStatus.pending,
      dependsOn: ['design-campaign'],
      metadata: {},
    );
    const generateVideos = WorkflowStep(
      id: 'generate-videos',
      title: 'Generate Videos',
      description: '',
      status: WorkflowStepStatus.pending,
      dependsOn: ['design-campaign'],
      metadata: {},
    );
    const publish = WorkflowStep(
      id: 'publish',
      title: 'Publish',
      description: '',
      status: WorkflowStepStatus.pending,
      dependsOn: ['generate-images', 'generate-videos'],
      metadata: {},
    );

    final steps = [
      analyzeMarket,
      designCampaign,
      generateImages,
      generateVideos,
      publish,
    ];
    final ids = steps.map((step) => step.id).toSet();

    // Every declared dependency resolves to a real step in the same
    // Workflow — WorkflowStep only ever carries this information; a
    // future WorkflowPlanner is responsible for validating it.
    for (final step in steps) {
      for (final dependencyId in step.dependsOn) {
        expect(ids, contains(dependencyId));
      }
    }
    expect(publish.dependsOn, ['generate-images', 'generate-videos']);
  });

  test(
    'WorkflowStep tolerates a dangling dependency without validating it',
    () {
      const step = WorkflowStep(
        id: 'publish',
        title: 'Publish',
        description: '',
        status: WorkflowStepStatus.pending,
        dependsOn: ['nonexistent-step'],
        metadata: {},
      );

      expect(step.dependsOn, ['nonexistent-step']);
    },
  );
}
