import 'package:pharos_ai_runtime/company/department.dart';
import 'package:pharos_ai_runtime/decision/decision_priority.dart';
import 'package:pharos_ai_runtime/decision/decision_reason.dart';
import 'package:pharos_ai_runtime/decision/decision_score.dart';
import 'package:pharos_ai_runtime/decision/decision_type.dart';
import 'package:pharos_ai_runtime/knowledge/fact_type.dart';

/// A decision is not a sentence — it is a structured business object.
/// The Runtime computes every field deterministically; the LLM only
/// ever receives a Decision and turns it into human-readable prose. It
/// never invents, reorders, or scores one itself.
class Decision {
  const Decision({
    required this.id,
    required this.department,
    required this.title,
    required this.type,
    required this.priority,
    required this.score,
    required this.blocked,
    required this.reasons,
    required this.evidence,
  });

  final String id;
  final Department department;
  final String title;
  final DecisionType type;
  final DecisionPriority priority;
  final DecisionScore score;

  /// True for work that cannot currently proceed due to a dependency —
  /// blocked work must never appear as a normal recommendation.
  final bool blocked;

  final List<DecisionReason> reasons;
  final List<FactType> evidence;

  /// How confident the Runtime is in this decision's evidence, 0.0-1.0.
  double get confidence => score.evidenceCompleteness;
}
