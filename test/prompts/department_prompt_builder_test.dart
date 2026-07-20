import 'package:pharos_ai_runtime/company/department.dart';
import 'package:pharos_ai_runtime/decision/decision.dart';
import 'package:pharos_ai_runtime/decision/decision_priority.dart';
import 'package:pharos_ai_runtime/decision/decision_reason.dart';
import 'package:pharos_ai_runtime/decision/decision_score.dart';
import 'package:pharos_ai_runtime/decision/decision_type.dart';
import 'package:pharos_ai_runtime/knowledge/fact_type.dart';
import 'package:pharos_ai_runtime/priorities/department_summary.dart';
import 'package:pharos_ai_runtime/priorities/executive_summary.dart';
import 'package:pharos_ai_runtime/prompts/department_prompt_builder.dart';
import 'package:test/test.dart';

Decision _topDecision() => const Decision(
  id: 'marketing.launch.prepare',
  department: Department.marketing,
  title: 'Prepare launch campaign',
  type: DecisionType.launch,
  priority: DecisionPriority.high,
  score: DecisionScore(impact: 0.8, urgency: 0.7, evidenceCompleteness: 1.0),
  blocked: false,
  reasons: [
    DecisionReason('Product exists'),
    DecisionReason('Brand assets ready'),
  ],
  evidence: [FactType.product, FactType.brandAsset],
);

Decision _blockedDecision() => const Decision(
  id: 'marketing.campaign.blocked',
  department: Department.marketing,
  title: 'Campaign Optimization',
  type: DecisionType.blocker,
  priority: DecisionPriority.critical,
  score: DecisionScore(impact: 0.9, urgency: 0.9, evidenceCompleteness: 1.0),
  blocked: true,
  reasons: [DecisionReason('Analytics unavailable')],
  evidence: [FactType.analyticsPlatform],
);

DepartmentSummary _departmentSummary() => DepartmentSummary(
  department: Department.marketing,
  decisionCount: 2,
  blockedCount: 1,
  observability: 0.6,
  readiness: 0.75,
  health: 0.7,
  topDecisions: [_topDecision()],
  blockedDecisions: [_blockedDecision()],
  missingOperationalData: const ['reachable'],
);

ExecutiveSummary _summary() => ExecutiveSummary(
  companyHealth: 0.79,
  topDecisions: [
    MergedDecision(
      decision: _topDecision(),
      affects: const [Department.marketing],
    ),
  ],
  blockedDecisions: [
    MergedDecision(
      decision: _blockedDecision(),
      affects: const [Department.marketing],
    ),
  ],
  observabilityGaps: const ['Analytics', 'Website Uptime'],
  departmentSummaries: [_departmentSummary()],
);

void main() {
  test(
    'buildReport() generates identical prompts for identical summaries and dates',
    () {
      const builder = DepartmentPromptBuilder();
      final date = DateTime(2026, 7, 20);

      final first = builder.buildReport(summary: _summary(), currentDate: date);
      final second = builder.buildReport(
        summary: _summary(),
        currentDate: date,
      );

      expect(first, second);
    },
  );

  test('buildReport() renders Executive Summary, Department Summaries, Health '
      'Scores, Top Decisions, Blocked Decisions, and Observability Gaps', () {
    const builder = DepartmentPromptBuilder();

    final prompt = builder.buildReport(
      summary: _summary(),
      currentDate: DateTime(2026, 7, 20),
    );

    expect(prompt, contains('Executive Summary:'));
    expect(prompt, contains('Company Health: 79%'));
    expect(prompt, contains('Department Summaries:'));
    expect(prompt, contains('Marketing:'));
    expect(prompt, contains('Health Scores:'));
    expect(prompt, contains('Top Decisions:'));
    expect(prompt, contains('Prepare launch campaign'));
    expect(prompt, contains('Affects: Marketing'));
    expect(prompt, contains('Blocked Decisions:'));
    expect(prompt, contains('Campaign Optimization'));
    expect(prompt, contains('Observability Gaps: Analytics, Website Uptime'));
  });

  test('buildReport() never mentions a raw signal name or a "Connect X" '
      'recommendation for observability gaps', () {
    const builder = DepartmentPromptBuilder();

    final prompt = builder.buildReport(
      summary: _summary(),
      currentDate: DateTime(2026, 7, 20),
    );

    expect(prompt, isNot(contains('Connect reachable')));
    expect(prompt, isNot(contains('reachable=')));
  });

  test('buildReport() instructs the LLM not to calculate its own priority or '
      'health score, and never to act on a blocked decision', () {
    const builder = DepartmentPromptBuilder();

    final prompt = builder.buildReport(
      summary: _summary(),
      currentDate: DateTime(2026, 7, 20),
    );

    expect(
      prompt,
      contains('do not calculate your own priority or health score'),
    );
    expect(
      prompt,
      contains(
        'Never recommend action on an item listed under Blocked Decisions',
      ),
    );
  });

  test('buildReport() includes the current date', () {
    const builder = DepartmentPromptBuilder();

    final prompt = builder.buildReport(
      summary: _summary(),
      currentDate: DateTime(2026, 7, 20),
    );

    expect(prompt, contains('2026-07-20'));
  });
}
