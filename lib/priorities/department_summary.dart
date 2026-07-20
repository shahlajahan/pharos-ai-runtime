import 'package:pharos_ai_runtime/company/department.dart';
import 'package:pharos_ai_runtime/decision/decision.dart';
import 'package:pharos_ai_runtime/operations/operational_snapshot.dart';
import 'package:pharos_ai_runtime/operations/state_completeness.dart';
import 'package:pharos_ai_runtime/priorities/priority_engine.dart';

/// One department's health, for the Executive dashboard: how much work
/// exists, how much of it is blocked, how observable the department's
/// entities are, how ready they are, and an overall deterministic
/// health score. Built once from an OperationalSnapshot and the
/// Decisions the Decision Engine already produced for it.
class DepartmentSummary {
  const DepartmentSummary({
    required this.department,
    required this.decisionCount,
    required this.blockedCount,
    required this.observability,
    required this.readiness,
    required this.health,
    required this.topDecisions,
    required this.blockedDecisions,
    required this.missingOperationalData,
  });

  factory DepartmentSummary.build({
    required OperationalSnapshot snapshot,
    required List<Decision> decisions,
    PriorityEngine priorityEngine = const PriorityEngine(),
  }) {
    const completeness = StateCompleteness();
    final blockedCount = decisions.where((decision) => decision.blocked).length;

    final readyStates = snapshot.states
        .where((state) => completeness.calculate(state) >= 1.0)
        .length;
    final readiness = snapshot.states.isEmpty
        ? 0.0
        : readyStates / snapshot.states.length;

    final blockedRatio = decisions.isEmpty
        ? 0.0
        : blockedCount / decisions.length;
    final health =
        ((snapshot.observabilityScore + readiness) / 2) * (1 - blockedRatio);

    return DepartmentSummary(
      department: snapshot.department,
      decisionCount: decisions.length,
      blockedCount: blockedCount,
      observability: snapshot.observabilityScore,
      readiness: readiness,
      health: health,
      topDecisions: priorityEngine.topDecisions(decisions),
      blockedDecisions: priorityEngine.blockedDecisions(decisions),
      missingOperationalData: snapshot.missingOperationalData,
    );
  }

  final Department department;
  final int decisionCount;
  final int blockedCount;

  /// The department's OperationalSnapshot.observabilityScore, 0.0-1.0.
  final double observability;

  /// The fraction of this department's tracked entities with every
  /// readiness signal known (not merely present), 0.0-1.0.
  final double readiness;

  /// Deterministic composite: the average of observability and
  /// readiness, discounted by how much of the department's work is
  /// currently blocked.
  final double health;

  final List<Decision> topDecisions;
  final List<Decision> blockedDecisions;

  /// Raw signal names still unknown — an implementation detail kept
  /// here only so ExecutiveAggregator can translate it into a
  /// dashboard-level observability gap; never rendered directly.
  final List<String> missingOperationalData;
}
