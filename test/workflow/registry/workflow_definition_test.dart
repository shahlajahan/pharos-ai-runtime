import 'package:pharos_ai_runtime/decision/decision_type.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_priority.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_step.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_step_status.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_type.dart';
import 'package:pharos_ai_runtime/workflow/registry/workflow_definition.dart';
import 'package:test/test.dart';

void main() {
  test('WorkflowDefinition stores every field exactly as constructed', () {
    const definition = WorkflowDefinition(
      id: 'launch_campaign',
      type: WorkflowType.launchCampaign,
      title: 'Launch Campaign',
      description: 'Launch a marketing campaign for a product.',
      supportedDecisionTypes: [DecisionType.launch],
      defaultPriority: WorkflowPriority.high,
      steps: [
        WorkflowStep(
          id: 'analyze-market',
          title: 'Analyze Market',
          description: '',
          status: WorkflowStepStatus.pending,
          dependsOn: [],
          metadata: {},
        ),
      ],
      metadata: {'category': 'marketing'},
    );

    expect(definition.id, 'launch_campaign');
    expect(definition.type, WorkflowType.launchCampaign);
    expect(definition.title, 'Launch Campaign');
    expect(definition.supportedDecisionTypes, [DecisionType.launch]);
    expect(definition.defaultPriority, WorkflowPriority.high);
    expect(definition.steps, hasLength(1));
    expect(definition.metadata, {'category': 'marketing'});
  });

  test('WorkflowDefinition is constructible as a compile-time constant, '
      'proving immutability', () {
    const definition = WorkflowDefinition(
      id: 'operations_review',
      type: WorkflowType.operations,
      title: 'Operations Review',
      description: '',
      supportedDecisionTypes: [DecisionType.review],
      defaultPriority: WorkflowPriority.medium,
      steps: [],
      metadata: {},
    );

    expect(definition, isA<WorkflowDefinition>());
  });
}
