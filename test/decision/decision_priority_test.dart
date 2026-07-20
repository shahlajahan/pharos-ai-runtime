import 'package:pharos_ai_runtime/decision/decision_priority.dart';
import 'package:test/test.dart';

void main() {
  test('fromScore() returns critical at or above 0.7', () {
    expect(DecisionPriority.fromScore(0.81), DecisionPriority.critical);
    expect(DecisionPriority.fromScore(0.7), DecisionPriority.critical);
  });

  test('fromScore() returns high between 0.5 and 0.7', () {
    expect(DecisionPriority.fromScore(0.56), DecisionPriority.high);
    expect(DecisionPriority.fromScore(0.5), DecisionPriority.high);
  });

  test('fromScore() returns medium between 0.3 and 0.5', () {
    expect(DecisionPriority.fromScore(0.4), DecisionPriority.medium);
    expect(DecisionPriority.fromScore(0.3), DecisionPriority.medium);
  });

  test('fromScore() returns low below 0.3', () {
    expect(DecisionPriority.fromScore(0.12), DecisionPriority.low);
    expect(DecisionPriority.fromScore(0.0), DecisionPriority.low);
  });
}
