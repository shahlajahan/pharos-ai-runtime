import 'package:pharos_ai_runtime/company/department.dart';
import 'package:pharos_ai_runtime/decision/decision.dart';
import 'package:pharos_ai_runtime/decision/decision_priority.dart';
import 'package:pharos_ai_runtime/decision/decision_reason.dart';
import 'package:pharos_ai_runtime/decision/decision_score.dart';
import 'package:pharos_ai_runtime/decision/decision_type.dart';
import 'package:pharos_ai_runtime/knowledge/fact_type.dart';
import 'package:pharos_ai_runtime/prompts/department_prompt_builder.dart';
import 'package:test/test.dart';

Decision _priorityDecision() => const Decision(
  id: 'marketing.analytics.connect',
  department: Department.marketing,
  title: 'Connect GA4',
  type: DecisionType.connect,
  priority: DecisionPriority.critical,
  score: DecisionScore(impact: 0.9, urgency: 0.9, evidenceCompleteness: 1.0),
  blocked: false,
  reasons: [
    DecisionReason('Website exists'),
    DecisionReason('Analytics unavailable'),
  ],
  evidence: [FactType.website, FactType.analyticsPlatform],
);

Decision _blockerDecision() => const Decision(
  id: 'marketing.campaign.blocked',
  department: Department.marketing,
  title: 'Campaign Optimization',
  type: DecisionType.blocker,
  priority: DecisionPriority.critical,
  score: DecisionScore(impact: 0.9, urgency: 0.9, evidenceCompleteness: 1.0),
  blocked: true,
  reasons: [DecisionReason('Analytics unavailable')],
  evidence: [FactType.website, FactType.analyticsPlatform],
);

List<Decision> _decisions(Department department) => [
  _priorityDecision(),
  _blockerDecision(),
];

void main() {
  test('build() generates identical prompts for identical decisions and '
      'dates', () {
    const builder = DepartmentPromptBuilder();
    final date = DateTime(2026, 7, 20);

    final first = builder.build(
      department: Department.marketing,
      decisions: _decisions(Department.marketing),
      currentDate: date,
    );
    final second = builder.build(
      department: Department.marketing,
      decisions: _decisions(Department.marketing),
      currentDate: date,
    );

    expect(first, second);
  });

  test(
    'build() separates Top Decisions from Blockers, and renders Evidence '
    'and Decision Scores — never a raw markdown excerpt or filesystem path',
    () {
      const builder = DepartmentPromptBuilder();

      final prompt = builder.build(
        department: Department.marketing,
        decisions: _decisions(Department.marketing),
        currentDate: DateTime(2026, 7, 20),
      );

      expect(prompt, contains('Marketing Top Decisions:'));
      expect(prompt, contains('Marketing Blockers:'));
      expect(prompt, contains('Marketing Informational Notes:'));
      expect(prompt, contains('Connect GA4'));
      expect(prompt, contains('Campaign Optimization'));
      expect(prompt, contains('Priority: critical'));
      expect(prompt, contains('Impact: 0.90'));
      expect(prompt, contains('Urgency: 0.90'));
      expect(prompt, contains('Confidence: 1.00'));
      expect(prompt, contains('Evidence: Website, Analytics Platform'));
      expect(prompt, isNot(contains('.md')));
      expect(prompt, isNot(contains('products/')));
    },
  );

  test('build() instructs the LLM to explain decisions, not calculate '
      'priority itself, and never recommend action on a blocked item', () {
    const builder = DepartmentPromptBuilder();

    final prompt = builder.build(
      department: Department.engineering,
      decisions: const [],
      currentDate: DateTime(2026, 7, 20),
    );

    expect(prompt, contains('do not calculate your own priority'));
    expect(
      prompt,
      contains('Never recommend action on an item listed under Blockers'),
    );
  });

  test('buildReport() composes one Top Decisions section per department, in '
      'order, even for departments with no decisions', () {
    const builder = DepartmentPromptBuilder();

    final report = builder.buildReport(
      decisionsByDepartment: {
        Department.marketing: _decisions(Department.marketing),
      },
      currentDate: DateTime(2026, 7, 20),
    );

    for (final department in Department.values) {
      expect(report, contains('${department.displayName} Top Decisions:'));
      expect(report, contains("Today's ${department.displayName} Priorities"));
    }
  });

  test('buildReport() instructs the model not to render Runtime-owned '
      'sections', () {
    const builder = DepartmentPromptBuilder();

    final report = builder.buildReport(
      decisionsByDepartment: const {},
      currentDate: DateTime(2026, 7, 20),
    );

    expect(report, contains('Blocked Items'));
    expect(report, contains('Missing Operational Data'));
    expect(report, contains('Runtime appends'));
  });

  test('buildReport() includes the current date', () {
    const builder = DepartmentPromptBuilder();

    final report = builder.buildReport(
      decisionsByDepartment: const {},
      currentDate: DateTime(2026, 7, 20),
    );

    expect(report, contains('2026-07-20'));
  });
}
