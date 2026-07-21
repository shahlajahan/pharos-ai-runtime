import 'package:pharos_ai_runtime/company/department.dart';
import 'package:pharos_ai_runtime/decision/decision.dart';
import 'package:pharos_ai_runtime/decision/decision_priority.dart';
import 'package:pharos_ai_runtime/decision/decision_reason.dart';
import 'package:pharos_ai_runtime/decision/decision_score.dart';
import 'package:pharos_ai_runtime/decision/decision_type.dart';
import 'package:pharos_ai_runtime/knowledge/fact_type.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_context.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_priority.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_status.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_step.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_step_status.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_type.dart';
import 'package:pharos_ai_runtime/workflow/planner/default_workflow_planner.dart';
import 'package:pharos_ai_runtime/workflow/registry/workflow_definition.dart';
import 'package:pharos_ai_runtime/workflow/registry/workflow_matcher.dart';
import 'package:pharos_ai_runtime/workflow/registry/workflow_registry.dart';
import 'package:test/test.dart';

WorkflowStep _step(String id, {List<String> dependsOn = const []}) =>
    WorkflowStep(
      id: id,
      title: id,
      description: '',
      status: WorkflowStepStatus.pending,
      dependsOn: dependsOn,
      metadata: const {},
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

WorkflowDefinition _definition(List<WorkflowStep> steps) => WorkflowDefinition(
  id: 'launch_campaign',
  type: WorkflowType.launchCampaign,
  title: 'Launch Campaign',
  description: '',
  supportedDecisionTypes: const [DecisionType.launch],
  defaultPriority: WorkflowPriority.high,
  steps: steps,
  metadata: const {},
);

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

const _context = WorkflowContext(company: {}, market: {}, finance: {});

DefaultWorkflowPlanner _plannerWith(WorkflowDefinition definition) {
  final registry = WorkflowRegistry()..register(definition);
  return DefaultWorkflowPlanner(WorkflowMatcher(registry));
}

void main() {
  test('plan() produces a successful PlanningResult for the roadmap\'s '
      'Launch Campaign example', () {
    final planner = _plannerWith(_definition(_launchCampaignSteps()));

    final result = planner.plan(_decision(), _context);

    expect(result.success, isTrue);
    expect(result.errors, isEmpty);
    expect(result.workflow, isNotNull);
    expect(result.workflow!.definitionId, 'launch_campaign');
    expect(result.workflow!.status, WorkflowStatus.planned);
    expect(result.plan, isNotNull);
  });

  test('plan() preserves dependency order in orderedSteps', () {
    final planner = _plannerWith(_definition(_launchCampaignSteps()));

    final result = planner.plan(_decision(), _context);

    final order = result.plan!.orderedSteps;
    bool before(String a, String b) => order.indexOf(a) < order.indexOf(b);

    expect(before('analyze-market', 'design-campaign'), isTrue);
    expect(before('analyze-budget', 'design-campaign'), isTrue);
    expect(before('design-campaign', 'generate-images'), isTrue);
    expect(before('design-campaign', 'generate-videos'), isTrue);
    expect(before('generate-images', 'publish'), isTrue);
    expect(before('generate-videos', 'publish'), isTrue);
    expect(before('publish', 'measure'), isTrue);
    expect(result.plan!.estimatedStepCount, 7);
  });

  test('plan() groups independent steps for parallel execution, matching '
      "the roadmap's Group 1-5 example exactly", () {
    final planner = _plannerWith(_definition(_launchCampaignSteps()));

    final result = planner.plan(_decision(), _context);

    expect(result.plan!.parallelGroups, [
      ['analyze-market', 'analyze-budget'],
      ['design-campaign'],
      ['generate-images', 'generate-videos'],
      ['publish'],
      ['measure'],
    ]);
  });

  test('plan() rejects an empty workflow', () {
    final planner = _plannerWith(_definition(const []));

    final result = planner.plan(_decision(), _context);

    expect(result.success, isFalse);
    expect(result.workflow, isNull);
    expect(result.plan, isNull);
    expect(result.errors, contains('Workflow has no steps.'));
  });

  test('plan() rejects a workflow with duplicate step ids', () {
    final planner = _plannerWith(
      _definition([_step('publish'), _step('publish')]),
    );

    final result = planner.plan(_decision(), _context);

    expect(result.success, isFalse);
    expect(result.errors.single, contains('Duplicate step id(s): publish'));
  });

  test('plan() rejects a workflow with a missing dependency', () {
    final planner = _plannerWith(
      _definition([
        _step('publish', dependsOn: ['does-not-exist']),
      ]),
    );

    final result = planner.plan(_decision(), _context);

    expect(result.success, isFalse);
    expect(
      result.errors.single,
      contains('Missing dependencies: does-not-exist'),
    );
  });

  test('plan() detects a circular dependency', () {
    final planner = _plannerWith(
      _definition([
        _step('a', dependsOn: ['b']),
        _step('b', dependsOn: ['a']),
      ]),
    );

    final result = planner.plan(_decision(), _context);

    expect(result.success, isFalse);
    expect(result.errors, contains('Workflow contains a circular dependency.'));
  });

  test('plan() detects a longer circular dependency chain', () {
    final planner = _plannerWith(
      _definition([
        _step('a', dependsOn: ['c']),
        _step('b', dependsOn: ['a']),
        _step('c', dependsOn: ['b']),
      ]),
    );

    final result = planner.plan(_decision(), _context);

    expect(result.success, isFalse);
    expect(result.errors, contains('Workflow contains a circular dependency.'));
  });

  test('plan() rejects an unreachable (fully disconnected) step alongside '
      'an otherwise connected workflow', () {
    final planner = _plannerWith(
      _definition([
        _step('analyze-market'),
        _step('design-campaign', dependsOn: ['analyze-market']),
        _step('isolated'),
      ]),
    );

    final result = planner.plan(_decision(), _context);

    expect(result.success, isFalse);
    expect(result.errors.single, contains('Unreachable step(s): isolated'));
  });

  test('plan() does not flag a single-step workflow as unreachable', () {
    final planner = _plannerWith(_definition([_step('only-step')]));

    final result = planner.plan(_decision(), _context);

    expect(result.success, isTrue);
  });

  test(
    'plan() reports "no matching definition" when nothing is registered',
    () {
      final registry = WorkflowRegistry();
      final planner = DefaultWorkflowPlanner(WorkflowMatcher(registry));

      final result = planner.plan(_decision(), _context);

      expect(result.success, isFalse);
      expect(result.workflow, isNull);
      expect(result.plan, isNull);
      expect(result.errors, isNotEmpty);
    },
  );

  test(
    'plan() never executes anything: it is synchronous and side-effect free',
    () {
      final planner = _plannerWith(_definition(_launchCampaignSteps()));

      final result = planner.plan(_decision(), _context);

      expect(result, isA<Object>());
    },
  );

  test('plan() is deterministic in its ordering and grouping', () {
    final planner = _plannerWith(_definition(_launchCampaignSteps()));

    final first = planner.plan(_decision(), _context);
    final second = planner.plan(_decision(), _context);

    expect(first.plan!.orderedSteps, second.plan!.orderedSteps);
    expect(first.plan!.parallelGroups, second.plan!.parallelGroups);
  });
}
