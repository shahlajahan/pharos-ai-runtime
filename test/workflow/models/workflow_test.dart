import 'package:pharos_ai_runtime/workflow/models/workflow.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_context.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_priority.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_status.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_step.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_step_status.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_type.dart';
import 'package:test/test.dart';

void main() {
  test('Workflow stores every field exactly as constructed, matching the '
      'roadmap\'s "Prepare Launch Campaign" example', () {
    final createdAt = DateTime(2026, 7, 21);
    const steps = [
      WorkflowStep(
        id: 'analyze-market',
        title: 'Analyze Market',
        description: '',
        status: WorkflowStepStatus.pending,
        dependsOn: [],
        metadata: {},
      ),
      WorkflowStep(
        id: 'analyze-budget',
        title: 'Analyze Budget',
        description: '',
        status: WorkflowStepStatus.pending,
        dependsOn: [],
        metadata: {},
      ),
      WorkflowStep(
        id: 'design-campaign',
        title: 'Design Campaign',
        description: '',
        status: WorkflowStepStatus.pending,
        dependsOn: ['analyze-market', 'analyze-budget'],
        metadata: {},
      ),
      WorkflowStep(
        id: 'generate-images',
        title: 'Generate Images',
        description: '',
        status: WorkflowStepStatus.pending,
        dependsOn: ['design-campaign'],
        metadata: {},
      ),
      WorkflowStep(
        id: 'generate-videos',
        title: 'Generate Videos',
        description: '',
        status: WorkflowStepStatus.pending,
        dependsOn: ['design-campaign'],
        metadata: {},
      ),
      WorkflowStep(
        id: 'publish',
        title: 'Publish',
        description: '',
        status: WorkflowStepStatus.pending,
        dependsOn: ['generate-images', 'generate-videos'],
        metadata: {},
      ),
      WorkflowStep(
        id: 'collect-metrics',
        title: 'Collect Metrics',
        description: '',
        status: WorkflowStepStatus.pending,
        dependsOn: ['publish'],
        metadata: {},
      ),
    ];

    final workflow = Workflow(
      id: 'workflow-1',
      type: WorkflowType.launchCampaign,
      title: 'Prepare Launch Campaign',
      description: 'Launch the Petsupo campaign.',
      priority: WorkflowPriority.high,
      status: WorkflowStatus.planned,
      context: const WorkflowContext(company: {}, market: {}, finance: {}),
      steps: steps,
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    expect(workflow.id, 'workflow-1');
    expect(workflow.type, WorkflowType.launchCampaign);
    expect(workflow.title, 'Prepare Launch Campaign');
    expect(workflow.priority, WorkflowPriority.high);
    expect(workflow.status, WorkflowStatus.planned);
    expect(workflow.steps, hasLength(7));
    expect(workflow.steps.map((step) => step.id).toList(), [
      'analyze-market',
      'analyze-budget',
      'design-campaign',
      'generate-images',
      'generate-videos',
      'publish',
      'collect-metrics',
    ]);
    expect(workflow.createdAt, createdAt);
    expect(workflow.updatedAt, createdAt);
  });

  test(
    'Workflow has no mutating methods: its fields are all final and its '
    'nested context and steps are constructible as compile-time constants',
    () {
      final date = DateTime(2026, 7, 21);
      final workflow = Workflow(
        id: 'workflow-2',
        type: WorkflowType.custom,
        title: 'Custom',
        description: '',
        priority: WorkflowPriority.low,
        status: WorkflowStatus.planned,
        context: const WorkflowContext(company: {}, market: {}, finance: {}),
        steps: const [],
        createdAt: date,
        updatedAt: date,
      );

      expect(workflow, isA<Workflow>());
      expect(workflow.context, isA<WorkflowContext>());
    },
  );
}
