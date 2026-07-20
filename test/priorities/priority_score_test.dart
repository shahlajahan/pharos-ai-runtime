import 'package:pharos_ai_runtime/company/department.dart';
import 'package:pharos_ai_runtime/decision/decision.dart';
import 'package:pharos_ai_runtime/decision/decision_priority.dart';
import 'package:pharos_ai_runtime/decision/decision_reason.dart';
import 'package:pharos_ai_runtime/decision/decision_score.dart';
import 'package:pharos_ai_runtime/decision/decision_type.dart';
import 'package:pharos_ai_runtime/knowledge/fact_type.dart';
import 'package:pharos_ai_runtime/priorities/priority_score.dart';
import 'package:test/test.dart';

void main() {
  test(
    'value multiplies impact, urgency, confidence, and evidenceCompleteness',
    () {
      const score = PriorityScore(
        impact: 0.9,
        urgency: 0.9,
        confidence: 1.0,
        evidenceCompleteness: 1.0,
      );

      expect(score.value, closeTo(0.81, 0.0001));
    },
  );

  test('value is 0.0 when any factor is 0.0', () {
    const score = PriorityScore(
      impact: 0.9,
      urgency: 0.9,
      confidence: 0.0,
      evidenceCompleteness: 1.0,
    );

    expect(score.value, 0.0);
  });

  test('percentage rounds value to a whole-number percentage', () {
    const score = PriorityScore(
      impact: 0.96,
      urgency: 1.0,
      confidence: 1.0,
      evidenceCompleteness: 1.0,
    );

    expect(score.percentage, 96);
  });

  test(
    'fromDecision() derives impact, urgency, and confidence from a Decision',
    () {
      const decision = Decision(
        id: 'marketing.analytics.connect',
        department: Department.marketing,
        title: 'Connect GA4',
        type: DecisionType.connect,
        priority: DecisionPriority.critical,
        score: DecisionScore(
          impact: 0.9,
          urgency: 0.9,
          evidenceCompleteness: 1.0,
        ),
        blocked: false,
        reasons: [DecisionReason('Website exists')],
        evidence: [FactType.website],
      );

      final score = PriorityScore.fromDecision(decision);

      expect(score.impact, 0.9);
      expect(score.urgency, 0.9);
      expect(score.confidence, 1.0);
      expect(score.evidenceCompleteness, 1.0);
    },
  );
}
