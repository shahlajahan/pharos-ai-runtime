import 'package:pharos_ai_runtime/company/department.dart';
import 'package:pharos_ai_runtime/decision/decision.dart';
import 'package:pharos_ai_runtime/decision/decision_priority.dart';
import 'package:pharos_ai_runtime/decision/decision_reason.dart';
import 'package:pharos_ai_runtime/decision/decision_score.dart';
import 'package:pharos_ai_runtime/decision/decision_type.dart';
import 'package:pharos_ai_runtime/knowledge/fact_type.dart';
import 'package:pharos_ai_runtime/priorities/decision_ranker.dart';
import 'package:test/test.dart';

Decision _decision({
  required String id,
  required double impact,
  bool blocked = false,
}) => Decision(
  id: id,
  department: Department.marketing,
  title: id,
  type: blocked ? DecisionType.blocker : DecisionType.connect,
  priority: DecisionPriority.high,
  score: DecisionScore(impact: impact, urgency: 1.0, evidenceCompleteness: 1.0),
  blocked: blocked,
  reasons: const [DecisionReason('synthetic')],
  evidence: const [FactType.product],
);

void main() {
  test('rank() orders decisions by score, highest first', () {
    const ranker = DecisionRanker();
    final decisions = [
      _decision(id: 'low', impact: 0.2),
      _decision(id: 'high', impact: 0.9),
      _decision(id: 'medium', impact: 0.5),
    ];

    final ranked = ranker.rank(decisions);

    expect(ranked.map((d) => d.id).toList(), ['high', 'medium', 'low']);
  });

  test('rank() excludes blocked decisions entirely, regardless of score', () {
    const ranker = DecisionRanker();
    final decisions = [
      _decision(id: 'blocked-high', impact: 0.99, blocked: true),
      _decision(id: 'allowed-low', impact: 0.1),
    ];

    final ranked = ranker.rank(decisions);

    expect(ranked.map((d) => d.id).toList(), ['allowed-low']);
  });

  test('rankBlocked() returns only blocked decisions, ranked by score', () {
    const ranker = DecisionRanker();
    final decisions = [
      _decision(id: 'blocked-low', impact: 0.2, blocked: true),
      _decision(id: 'blocked-high', impact: 0.9, blocked: true),
      _decision(id: 'allowed', impact: 0.5),
    ];

    final ranked = ranker.rankBlocked(decisions);

    expect(ranked.map((d) => d.id).toList(), ['blocked-high', 'blocked-low']);
  });

  test('rank() breaks ties deterministically by id', () {
    const ranker = DecisionRanker();
    final decisions = [
      _decision(id: 'zzz', impact: 0.5),
      _decision(id: 'aaa', impact: 0.5),
    ];

    final ranked = ranker.rank(decisions);

    expect(ranked.map((d) => d.id).toList(), ['aaa', 'zzz']);
  });

  test('rank() respects the limit', () {
    const ranker = DecisionRanker();
    final decisions = [
      _decision(id: 'a', impact: 0.9),
      _decision(id: 'b', impact: 0.8),
      _decision(id: 'c', impact: 0.7),
      _decision(id: 'd', impact: 0.6),
    ];

    final ranked = ranker.rank(decisions, limit: 2);

    expect(ranked, hasLength(2));
    expect(ranked.map((d) => d.id).toList(), ['a', 'b']);
  });

  test('rank() is deterministic across repeated calls', () {
    const ranker = DecisionRanker();
    final decisions = [
      _decision(id: 'a', impact: 0.9),
      _decision(id: 'b', impact: 0.8),
    ];

    expect(ranker.rank(decisions), ranker.rank(decisions).toList());
  });
}
