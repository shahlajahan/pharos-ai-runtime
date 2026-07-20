/// Priority = BusinessImpact x Urgency x EvidenceCompleteness.
/// Deterministic: no AI, just a product of three 0.0-1.0 factors the
/// Runtime computes itself.
class DecisionScore {
  const DecisionScore({
    required this.impact,
    required this.urgency,
    required this.evidenceCompleteness,
  });

  final double impact;
  final double urgency;
  final double evidenceCompleteness;

  double get value => impact * urgency * evidenceCompleteness;
}
