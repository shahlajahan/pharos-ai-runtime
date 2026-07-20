import 'package:pharos_ai_runtime/decision/decision_score.dart';
import 'package:test/test.dart';

void main() {
  test('value multiplies impact, urgency, and evidenceCompleteness', () {
    const score = DecisionScore(
      impact: 0.9,
      urgency: 0.9,
      evidenceCompleteness: 1.0,
    );

    expect(score.value, closeTo(0.81, 0.0001));
  });

  test('value is 0.0 when any factor is 0.0', () {
    const score = DecisionScore(
      impact: 0.9,
      urgency: 0.0,
      evidenceCompleteness: 1.0,
    );

    expect(score.value, 0.0);
  });

  test('value is deterministic', () {
    const score = DecisionScore(
      impact: 0.5,
      urgency: 0.5,
      evidenceCompleteness: 0.5,
    );

    expect(score.value, score.value);
  });
}
