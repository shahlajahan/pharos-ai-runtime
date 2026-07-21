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
import 'package:pharos_ai_runtime/workflow/registry/workflow_matcher.dart';
import 'package:pharos_ai_runtime/workflow/registry/workflow_registry.dart';
import 'package:test/test.dart';

WorkflowDefinition _launchCampaignDefinition() => const WorkflowDefinition(
  id: 'launch_campaign',
  type: WorkflowType.launchCampaign,
  title: 'Launch Campaign',
  description: '',
  supportedDecisionTypes: [DecisionType.launch],
  defaultPriority: WorkflowPriority.high,
  steps: [],
  metadata: {},
);

Decision _decision(String title, DecisionType type) => Decision(
  id: 'marketing.$type',
  department: Department.marketing,
  title: title,
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

void main() {
  test('match() selects the registered definition matching the roadmap\'s '
      '"Prepare Launch Campaign" example', () {
    final registry = WorkflowRegistry()..register(_launchCampaignDefinition());
    final matcher = WorkflowMatcher(registry);

    final matched = matcher.match(
      _decision('Prepare Launch Campaign', DecisionType.launch),
    );

    expect(matched, isNotNull);
    expect(matched!.id, 'launch_campaign');
  });

  test('match() returns null when the registry has no matching definition', () {
    final registry = WorkflowRegistry();
    final matcher = WorkflowMatcher(registry);

    final matched = matcher.match(
      _decision('Review Docs', DecisionType.review),
    );

    expect(matched, isNull);
  });

  test('match() never mutates the registry: it only selects a definition', () {
    final registry = WorkflowRegistry()..register(_launchCampaignDefinition());
    final matcher = WorkflowMatcher(registry);

    matcher.match(_decision('Prepare Launch Campaign', DecisionType.launch));

    expect(registry.all(), hasLength(1));
  });
}
