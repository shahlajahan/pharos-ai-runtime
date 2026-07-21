import 'package:pharos_ai_runtime/company/department.dart';
import 'package:pharos_ai_runtime/decision/decision.dart';
import 'package:pharos_ai_runtime/decision/decision_priority.dart';
import 'package:pharos_ai_runtime/decision/decision_reason.dart';
import 'package:pharos_ai_runtime/decision/decision_score.dart';
import 'package:pharos_ai_runtime/decision/decision_type.dart';
import 'package:pharos_ai_runtime/knowledge/fact_type.dart';
import 'package:pharos_ai_runtime/workflow/contracts/workflow_planner.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_context.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_priority.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_status.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_type.dart';
import 'package:test/test.dart';

class _FakeWorkflowPlanner implements WorkflowPlanner {
  @override
  Workflow plan(Decision decision, WorkflowContext context) {
    return Workflow(
      id: 'planned-${decision.id}',
      type: WorkflowType.launchCampaign,
      title: decision.title,
      description: 'Planned from ${decision.id}',
      priority: WorkflowPriority.high,
      status: WorkflowStatus.planned,
      context: context,
      steps: const [],
      createdAt: DateTime(2026, 7, 21),
      updatedAt: DateTime(2026, 7, 21),
    );
  }
}

Decision _decision() => const Decision(
  id: 'marketing.launch.prepare',
  department: Department.marketing,
  title: 'Prepare Launch Campaign',
  type: DecisionType.launch,
  priority: DecisionPriority.high,
  score: DecisionScore(impact: 0.8, urgency: 0.7, evidenceCompleteness: 1.0),
  blocked: false,
  reasons: [DecisionReason('Product exists')],
  evidence: [FactType.product],
);

void main() {
  test(
    'WorkflowPlanner is implementable and turns a Decision into a Workflow',
    () {
      final planner = _FakeWorkflowPlanner();

      final workflow = planner.plan(
        _decision(),
        const WorkflowContext(company: {}, market: {}, finance: {}),
      );

      expect(workflow.title, 'Prepare Launch Campaign');
      expect(workflow.status, WorkflowStatus.planned);
    },
  );

  test('WorkflowPlanner.plan() is synchronous: it returns a Workflow '
      'directly, not a Future', () {
    final planner = _FakeWorkflowPlanner();

    final result = planner.plan(
      _decision(),
      const WorkflowContext(company: {}, market: {}, finance: {}),
    );

    expect(result, isA<Workflow>());
  });
}
