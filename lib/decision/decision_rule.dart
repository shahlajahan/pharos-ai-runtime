import 'package:pharos_ai_runtime/company/department.dart';
import 'package:pharos_ai_runtime/decision/decision_reason.dart';
import 'package:pharos_ai_runtime/decision/decision_type.dart';
import 'package:pharos_ai_runtime/knowledge/fact_type.dart';
import 'package:pharos_ai_runtime/operations/operational_snapshot.dart';

/// A single deterministic IF/THEN rule: given a department's
/// OperationalSnapshot, decide whether this rule fires, and if so, what
/// Decision it produces. Rules are data passed into DecisionEngine, not
/// logic hardcoded inside it — new rules can be configured without
/// touching the engine, and the LLM never invents one itself.
class DecisionRule {
  const DecisionRule({
    required this.id,
    required this.department,
    required this.type,
    required this.title,
    required this.impact,
    required this.urgency,
    required this.appliesTo,
    required this.reasonsFor,
    required this.evidenceFor,
    this.evidenceCompleteness = _fullyKnown,
  });

  final String id;
  final Department department;
  final DecisionType type;
  final String title;

  /// 0.0-1.0: how much this decision matters if acted on.
  final double impact;

  /// 0.0-1.0: how time-sensitive this decision is.
  final double urgency;

  final bool Function(OperationalSnapshot snapshot) appliesTo;
  final List<DecisionReason> Function(OperationalSnapshot snapshot) reasonsFor;
  final List<FactType> Function(OperationalSnapshot snapshot) evidenceFor;

  /// 0.0-1.0: how certain the Runtime is in this decision's premises.
  /// Defaults to fully known, since a rule only ever fires on
  /// deterministically resolved signals — never on an unknown one.
  final double Function(OperationalSnapshot snapshot) evidenceCompleteness;

  static double _fullyKnown(OperationalSnapshot snapshot) => 1.0;
}
