/// A decision's deterministic priority tier, derived from its
/// DecisionScore. No AI: a fixed set of thresholds on
/// impact x urgency x evidenceCompleteness.
enum DecisionPriority {
  critical,
  high,
  medium,
  low;

  static DecisionPriority fromScore(double score) {
    if (score >= 0.7) return DecisionPriority.critical;
    if (score >= 0.5) return DecisionPriority.high;
    if (score >= 0.3) return DecisionPriority.medium;
    return DecisionPriority.low;
  }
}
