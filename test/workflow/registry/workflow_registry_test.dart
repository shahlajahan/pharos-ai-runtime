import 'package:pharos_ai_runtime/company/department.dart';
import 'package:pharos_ai_runtime/decision/decision.dart';
import 'package:pharos_ai_runtime/decision/decision_priority.dart';
import 'package:pharos_ai_runtime/decision/decision_reason.dart';
import 'package:pharos_ai_runtime/decision/decision_score.dart';
import 'package:pharos_ai_runtime/decision/decision_type.dart';
import 'package:pharos_ai_runtime/knowledge/fact_type.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_priority.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_type.dart';
import 'package:pharos_ai_runtime/workflow/registry/workflow_definition.dart';
import 'package:pharos_ai_runtime/workflow/registry/workflow_registry.dart';
import 'package:test/test.dart';

WorkflowDefinition _definition({
  required String id,
  required WorkflowType type,
  List<DecisionType> supportedDecisionTypes = const [],
}) => WorkflowDefinition(
  id: id,
  type: type,
  title: id,
  description: '',
  supportedDecisionTypes: supportedDecisionTypes,
  defaultPriority: WorkflowPriority.medium,
  steps: const [],
  metadata: const {},
);

Decision _decision(DecisionType type) => Decision(
  id: 'test.$type',
  department: Department.marketing,
  title: 'Test Decision',
  type: type,
  priority: DecisionPriority.high,
  score: const DecisionScore(
    impact: 0.9,
    urgency: 0.9,
    evidenceCompleteness: 1.0,
  ),
  blocked: false,
  reasons: const [DecisionReason('synthetic')],
  evidence: const [FactType.product],
);

/// The seven initial built-in workflows named in the task, registered
/// here to demonstrate the registry supports exactly this catalog.
List<WorkflowDefinition> _builtIns() => [
  _definition(
    id: 'launch_campaign',
    type: WorkflowType.launchCampaign,
    supportedDecisionTypes: const [DecisionType.launch],
  ),
  _definition(
    id: 'partner_outreach',
    type: WorkflowType.partnerOutreach,
    supportedDecisionTypes: const [DecisionType.connect],
  ),
  _definition(
    id: 'product_release',
    type: WorkflowType.productRelease,
    supportedDecisionTypes: const [DecisionType.launch],
  ),
  _definition(
    id: 'customer_support',
    type: WorkflowType.customerSupport,
    supportedDecisionTypes: const [DecisionType.fix],
  ),
  _definition(
    id: 'engineering_task',
    type: WorkflowType.engineeringTask,
    supportedDecisionTypes: const [DecisionType.improve],
  ),
  _definition(
    id: 'finance_review',
    type: WorkflowType.financeReview,
    supportedDecisionTypes: const [DecisionType.review],
  ),
  _definition(
    id: 'operations_review',
    type: WorkflowType.operations,
    supportedDecisionTypes: const [DecisionType.monitor],
  ),
];

void main() {
  test('register() adds a WorkflowDefinition, visible via all()', () {
    final registry = WorkflowRegistry();

    registry.register(
      _definition(id: 'launch_campaign', type: WorkflowType.launchCampaign),
    );

    expect(registry.all().map((d) => d.id), ['launch_campaign']);
  });

  test('register() supports registering all seven built-in workflows', () {
    final registry = WorkflowRegistry();

    for (final definition in _builtIns()) {
      registry.register(definition);
    }

    expect(registry.all(), hasLength(7));
    expect(registry.all().map((d) => d.id).toSet(), {
      'launch_campaign',
      'partner_outreach',
      'product_release',
      'customer_support',
      'engineering_task',
      'finance_review',
      'operations_review',
    });
  });

  test('register() throws ArgumentError for a duplicate id rather than '
      'silently overwriting it', () {
    final registry = WorkflowRegistry();
    registry.register(
      _definition(id: 'launch_campaign', type: WorkflowType.launchCampaign),
    );

    expect(
      () => registry.register(
        _definition(id: 'launch_campaign', type: WorkflowType.productRelease),
      ),
      throwsArgumentError,
    );
    expect(registry.all(), hasLength(1));
    expect(registry.all().single.type, WorkflowType.launchCampaign);
  });

  test('unregister() removes a definition by id', () {
    final registry = WorkflowRegistry();
    registry.register(
      _definition(id: 'launch_campaign', type: WorkflowType.launchCampaign),
    );

    registry.unregister('launch_campaign');

    expect(registry.all(), isEmpty);
  });

  test('unregister() is a no-op for an id that was never registered', () {
    final registry = WorkflowRegistry();

    registry.unregister('nonexistent');

    expect(registry.all(), isEmpty);
  });

  test('findByType() returns every definition matching the given type', () {
    final registry = WorkflowRegistry();
    registry.register(
      _definition(id: 'launch_campaign', type: WorkflowType.launchCampaign),
    );
    registry.register(
      _definition(id: 'launch_campaign_v2', type: WorkflowType.launchCampaign),
    );
    registry.register(
      _definition(id: 'finance_review', type: WorkflowType.financeReview),
    );

    final matches = registry.findByType(WorkflowType.launchCampaign);

    expect(matches.map((d) => d.id).toSet(), {
      'launch_campaign',
      'launch_campaign_v2',
    });
  });

  test('findByType() returns an empty list when nothing matches', () {
    final registry = WorkflowRegistry();

    expect(registry.findByType(WorkflowType.launchCampaign), isEmpty);
  });

  test("findByDecision() returns the definition whose supportedDecisionTypes "
      'includes the Decision type', () {
    final registry = WorkflowRegistry();
    for (final definition in _builtIns()) {
      registry.register(definition);
    }

    final match = registry.findByDecision(_decision(DecisionType.launch));

    expect(match, isNotNull);
    expect(match!.id, 'launch_campaign');
  });

  test('findByDecision() returns null when no definition matches', () {
    final registry = WorkflowRegistry();

    expect(registry.findByDecision(_decision(DecisionType.risk)), isNull);
  });

  test('findByDecision() returns the first-registered match when more than '
      'one definition supports the same DecisionType, for deterministic '
      'ordering', () {
    final registry = WorkflowRegistry();
    registry.register(
      _definition(
        id: 'first',
        type: WorkflowType.launchCampaign,
        supportedDecisionTypes: const [DecisionType.launch],
      ),
    );
    registry.register(
      _definition(
        id: 'second',
        type: WorkflowType.productRelease,
        supportedDecisionTypes: const [DecisionType.launch],
      ),
    );

    final match = registry.findByDecision(_decision(DecisionType.launch));

    expect(match!.id, 'first');
  });
}
