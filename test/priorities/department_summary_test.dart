import 'package:pharos_ai_runtime/company/department.dart';
import 'package:pharos_ai_runtime/decision/decision.dart';
import 'package:pharos_ai_runtime/decision/decision_priority.dart';
import 'package:pharos_ai_runtime/decision/decision_reason.dart';
import 'package:pharos_ai_runtime/decision/decision_score.dart';
import 'package:pharos_ai_runtime/decision/decision_type.dart';
import 'package:pharos_ai_runtime/knowledge/fact_type.dart';
import 'package:pharos_ai_runtime/operations/operational_snapshot.dart';
import 'package:pharos_ai_runtime/operations/operational_state.dart';
import 'package:pharos_ai_runtime/priorities/department_summary.dart';
import 'package:test/test.dart';

OperationalState _fullyKnownState(String name) => OperationalState(
  factId: 'brand-asset:$name',
  factType: FactType.brandAsset,
  name: name,
  signals: const {'exists': SignalState.yes},
);

OperationalState _partiallyKnownState(String name) => OperationalState(
  factId: 'website:$name',
  factType: FactType.website,
  name: name,
  signals: const {
    'exists': SignalState.yes,
    'reachable': SignalState.unknown,
    'analyticsConnected': SignalState.no,
  },
);

Decision _decision({required String id, bool blocked = false}) => Decision(
  id: id,
  department: Department.marketing,
  title: id,
  type: blocked ? DecisionType.blocker : DecisionType.connect,
  priority: DecisionPriority.high,
  score: const DecisionScore(
    impact: 0.5,
    urgency: 0.5,
    evidenceCompleteness: 1.0,
  ),
  blocked: blocked,
  reasons: const [DecisionReason('synthetic')],
  evidence: const [FactType.product],
);

void main() {
  test('build() computes readiness as the fraction of fully-known states', () {
    final snapshot = OperationalSnapshot(
      department: Department.marketing,
      states: [_fullyKnownState('a'), _partiallyKnownState('b')],
      allowed: const [],
      blocked: const [],
      observabilityScore: 0.75,
      missingOperationalData: const ['reachable'],
      missingFactTypes: const [],
    );

    final summary = DepartmentSummary.build(
      snapshot: snapshot,
      decisions: const [],
    );

    expect(summary.readiness, 0.5);
  });

  test('build() reflects decision and blocked counts', () {
    final snapshot = OperationalSnapshot(
      department: Department.marketing,
      states: const [],
      allowed: const [],
      blocked: const [],
      observabilityScore: 1.0,
      missingOperationalData: const [],
      missingFactTypes: const [],
    );
    final decisions = [_decision(id: 'a'), _decision(id: 'b', blocked: true)];

    final summary = DepartmentSummary.build(
      snapshot: snapshot,
      decisions: decisions,
    );

    expect(summary.decisionCount, 2);
    expect(summary.blockedCount, 1);
  });

  test(
    'build() discounts health by the fraction of decisions that are blocked',
    () {
      final snapshot = OperationalSnapshot(
        department: Department.marketing,
        states: [_fullyKnownState('a')],
        allowed: const [],
        blocked: const [],
        observabilityScore: 1.0,
        missingOperationalData: const [],
        missingFactTypes: const [],
      );

      final noneBlocked = DepartmentSummary.build(
        snapshot: snapshot,
        decisions: [_decision(id: 'a')],
      );
      final halfBlocked = DepartmentSummary.build(
        snapshot: snapshot,
        decisions: [
          _decision(id: 'a'),
          _decision(id: 'b', blocked: true),
        ],
      );

      expect(noneBlocked.health, greaterThan(halfBlocked.health));
    },
  );

  test(
    'build() returns clean 0.0 values when there are no states or decisions',
    () {
      final snapshot = OperationalSnapshot(
        department: Department.finance,
        states: const [],
        allowed: const [],
        blocked: const [],
        observabilityScore: 0.0,
        missingOperationalData: const [],
        missingFactTypes: const [],
      );

      final summary = DepartmentSummary.build(
        snapshot: snapshot,
        decisions: const [],
      );

      expect(summary.readiness, 0.0);
      expect(summary.health, 0.0);
      expect(summary.decisionCount, 0);
      expect(summary.blockedCount, 0);
    },
  );

  test('build() carries missingOperationalData through from the snapshot', () {
    final snapshot = OperationalSnapshot(
      department: Department.marketing,
      states: const [],
      allowed: const [],
      blocked: const [],
      observabilityScore: 0.0,
      missingOperationalData: const ['reachable', 'lastDeploy'],
      missingFactTypes: const [],
    );

    final summary = DepartmentSummary.build(
      snapshot: snapshot,
      decisions: const [],
    );

    expect(summary.missingOperationalData, ['reachable', 'lastDeploy']);
  });

  test(
    'build() exposes topDecisions and blockedDecisions capped and ranked',
    () {
      final snapshot = OperationalSnapshot(
        department: Department.marketing,
        states: const [],
        allowed: const [],
        blocked: const [],
        observabilityScore: 1.0,
        missingOperationalData: const [],
        missingFactTypes: const [],
      );
      final decisions = [
        _decision(id: 'allowed'),
        _decision(id: 'blocked', blocked: true),
      ];

      final summary = DepartmentSummary.build(
        snapshot: snapshot,
        decisions: decisions,
      );

      expect(summary.topDecisions.map((d) => d.id), ['allowed']);
      expect(summary.blockedDecisions.map((d) => d.id), ['blocked']);
    },
  );
}
