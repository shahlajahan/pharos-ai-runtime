import 'package:pharos_ai_runtime/decision/decision.dart';
import 'package:pharos_ai_runtime/priorities/decision_ranker.dart';

/// Turns one department's raw Decisions (already produced by the
/// Decision Engine) into the department's top actionable priorities and
/// top blockers, ranked by [PriorityScore] rather than the Decision
/// Engine's own department-local score. No AI: purely a ranking step.
class PriorityEngine {
  const PriorityEngine({
    this.ranker = const DecisionRanker(),
    this.topCount = 3,
  });

  final DecisionRanker ranker;
  final int topCount;

  List<Decision> topDecisions(List<Decision> decisions) =>
      ranker.rank(decisions, limit: topCount);

  List<Decision> blockedDecisions(List<Decision> decisions) =>
      ranker.rankBlocked(decisions, limit: topCount);
}
