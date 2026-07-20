import 'package:pharos_ai_runtime/decision/decision.dart';

/// Priority = Impact x Urgency x Confidence x EvidenceCompleteness.
/// Deterministic: no AI, just a product of four 0.0-1.0 factors already
/// computed by the Decision Engine.
class PriorityScore {
  const PriorityScore({
    required this.impact,
    required this.urgency,
    required this.confidence,
    required this.evidenceCompleteness,
  });

  factory PriorityScore.fromDecision(Decision decision) => PriorityScore(
    impact: decision.score.impact,
    urgency: decision.score.urgency,
    confidence: decision.confidence,
    evidenceCompleteness: decision.score.evidenceCompleteness,
  );

  final double impact;
  final double urgency;
  final double confidence;
  final double evidenceCompleteness;

  double get value => impact * urgency * confidence * evidenceCompleteness;

  /// [value] expressed as a whole-number percentage, for example 96.
  int get percentage => (value * 100).round();
}
