import 'package:pharos_ai_runtime/decision/decision.dart';
import 'package:pharos_ai_runtime/priorities/priority_score.dart';

/// Deterministically ranks Decisions by [PriorityScore], highest first,
/// breaking ties by id so the same input always produces the same
/// order. A blocked decision is never eligible to become a ranked "top
/// decision" regardless of its score — the Runtime understands that
/// dependency: a decision that cannot proceed stays out of the
/// actionable ranking no matter how high-value it would otherwise be.
class DecisionRanker {
  const DecisionRanker();

  List<Decision> rank(List<Decision> decisions, {int? limit}) =>
      _sorted(decisions.where((decision) => !decision.blocked), limit);

  List<Decision> rankBlocked(List<Decision> decisions, {int? limit}) =>
      _sorted(decisions.where((decision) => decision.blocked), limit);

  List<Decision> _sorted(Iterable<Decision> decisions, int? limit) {
    final sorted = decisions.toList()
      ..sort((a, b) {
        final byScore = PriorityScore.fromDecision(
          b,
        ).value.compareTo(PriorityScore.fromDecision(a).value);
        return byScore != 0 ? byScore : a.id.compareTo(b.id);
      });

    return limit == null ? sorted : sorted.take(limit).toList();
  }
}
