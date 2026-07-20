import 'package:pharos_ai_runtime/company/department.dart';
import 'package:pharos_ai_runtime/decision/decision.dart';
import 'package:pharos_ai_runtime/decision/decision_priority.dart';
import 'package:pharos_ai_runtime/decision/decision_reason.dart';
import 'package:pharos_ai_runtime/decision/decision_score.dart';
import 'package:pharos_ai_runtime/decision/decision_type.dart';
import 'package:pharos_ai_runtime/knowledge/fact_type.dart';
import 'package:pharos_ai_runtime/priorities/priority_engine.dart';
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
  test('topDecisions() caps at topCount, highest score first', () {
    const engine = PriorityEngine(topCount: 3);
    final decisions = [
      for (var i = 0; i < 5; i++) _decision(id: 'd$i', impact: 0.1 * (i + 1)),
    ];

    final top = engine.topDecisions(decisions);

    expect(top, hasLength(3));
    expect(top.map((d) => d.id).toList(), ['d4', 'd3', 'd2']);
  });

  test(
    'blockedDecisions() caps at topCount and only includes blocked ones',
    () {
      const engine = PriorityEngine(topCount: 3);
      final decisions = [
        for (var i = 0; i < 5; i++)
          _decision(id: 'b$i', impact: 0.1 * (i + 1), blocked: true),
        _decision(id: 'allowed', impact: 0.99),
      ];

      final blocked = engine.blockedDecisions(decisions);

      expect(blocked, hasLength(3));
      expect(blocked.every((d) => d.blocked), isTrue);
    },
  );

  test('topDecisions() never includes a blocked decision', () {
    const engine = PriorityEngine();
    final decisions = [
      _decision(id: 'blocked', impact: 0.99, blocked: true),
      _decision(id: 'allowed', impact: 0.1),
    ];

    final top = engine.topDecisions(decisions);

    expect(top.map((d) => d.id), isNot(contains('blocked')));
  });
}
