import 'package:pharos_ai_runtime/workflow/models/workflow_context.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_status.dart';
import 'package:pharos_ai_runtime/workflow/planner/planning_result.dart';
import 'package:pharos_ai_runtime/workflow/planner/workflow_instance.dart';
import 'package:pharos_ai_runtime/workflow/planner/workflow_plan.dart';
import 'package:test/test.dart';

void main() {
  test('a successful PlanningResult carries a WorkflowInstance and a '
      'WorkflowPlan', () {
    final now = DateTime(2026, 7, 21);
    final result = PlanningResult(
      success: true,
      workflow: WorkflowInstance(
        id: 'launch_campaign:decision-1',
        definitionId: 'launch_campaign',
        status: WorkflowStatus.planned,
        context: const WorkflowContext(company: {}, market: {}, finance: {}),
        steps: const [],
        createdAt: now,
        plannedAt: now,
      ),
      plan: const WorkflowPlan(
        orderedSteps: [],
        parallelGroups: [],
        blockedSteps: [],
        warnings: [],
        estimatedStepCount: 0,
      ),
      errors: const [],
      warnings: const [],
    );

    expect(result.success, isTrue);
    expect(result.workflow, isNotNull);
    expect(result.plan, isNotNull);
    expect(result.errors, isEmpty);
  });

  test('a failed PlanningResult never carries a WorkflowInstance or a '
      'WorkflowPlan', () {
    const result = PlanningResult(
      success: false,
      workflow: null,
      plan: null,
      errors: ['Workflow has no steps.'],
      warnings: [],
    );

    expect(result.success, isFalse);
    expect(result.workflow, isNull);
    expect(result.plan, isNull);
    expect(result.errors, ['Workflow has no steps.']);
  });
}
