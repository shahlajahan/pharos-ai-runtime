import 'package:pharos_ai_runtime/company/department.dart';
import 'package:pharos_ai_runtime/decision/decision.dart';
import 'package:pharos_ai_runtime/priorities/decision_ranker.dart';
import 'package:pharos_ai_runtime/priorities/department_summary.dart';
import 'package:pharos_ai_runtime/priorities/executive_summary.dart';
import 'package:pharos_ai_runtime/priorities/priority_score.dart';

/// Builds the ExecutiveSummary from every department's DepartmentSummary.
/// The Executive never invents work — it only aggregates: merging
/// decisions that were independently raised by more than one department,
/// ranking the result, translating raw missing signals into dashboard
/// categories, and averaging department health into one company health
/// score. No filesystem, no connectors, no LLM.
class ExecutiveAggregator {
  const ExecutiveAggregator({
    this.ranker = const DecisionRanker(),
    this.topCount = 3,
  });

  final DecisionRanker ranker;
  final int topCount;

  /// Maps a raw OperationalState signal name to the dashboard category
  /// the Executive should see instead (for example "reachable" ->
  /// "Website Uptime"). Signals map many-to-one on purpose: connecting
  /// one analytics platform resolves several underlying signals at
  /// once, and the Executive should see that as a single gap.
  static const Map<String, String> observabilityCategories = {
    'reachable': 'Website Uptime',
    'lastDeploy': 'Deploy Status',
    'analyticsConnected': 'Analytics',
    'trafficMetricsAvailable': 'Analytics',
    'configured': 'Analytics',
    'liveMetricsAvailable': 'Analytics',
    'lastSync': 'Analytics',
    'followers': 'Social Metrics',
    'engagement': 'Social Metrics',
    'postingFrequency': 'Social Metrics',
    'insightsConnected': 'Social Metrics',
    'ciStatus': 'Repository Metrics',
    'deploymentStatus': 'Repository Metrics',
    'documentationCoverage': 'Repository Metrics',
    'billingStatus': 'Billing',
    'revenueAvailable': 'Revenue',
  };

  ExecutiveSummary aggregate(List<DepartmentSummary> summaries) {
    final companyHealth = summaries.isEmpty
        ? 0.0
        : summaries.map((summary) => summary.health).reduce((a, b) => a + b) /
              summaries.length;

    final allTop = [for (final summary in summaries) ...summary.topDecisions];
    final allBlocked = [
      for (final summary in summaries) ...summary.blockedDecisions,
    ];

    return ExecutiveSummary(
      companyHealth: companyHealth,
      topDecisions: _mergeAndRank(allTop),
      blockedDecisions: _mergeAndRank(allBlocked),
      observabilityGaps: _observabilityGaps(summaries),
      departmentSummaries: summaries,
    );
  }

  List<MergedDecision> _mergeAndRank(List<Decision> decisions) {
    final byTitle = <String, List<Decision>>{};

    for (final decision in decisions) {
      byTitle.putIfAbsent(decision.title, () => []).add(decision);
    }

    final merged = [for (final group in byTitle.values) _merge(group)];

    merged.sort((a, b) {
      final byScore = PriorityScore.fromDecision(
        b.decision,
      ).value.compareTo(PriorityScore.fromDecision(a.decision).value);
      return byScore != 0 ? byScore : a.decision.id.compareTo(b.decision.id);
    });

    return merged.take(topCount).toList();
  }

  MergedDecision _merge(List<Decision> duplicates) {
    final sorted = [...duplicates]
      ..sort(
        (a, b) => PriorityScore.fromDecision(
          b,
        ).value.compareTo(PriorityScore.fromDecision(a).value),
      );

    final affects = <Department>{
      for (final decision in sorted) decision.department,
    }.toList()..sort((a, b) => a.name.compareTo(b.name));

    return MergedDecision(decision: sorted.first, affects: affects);
  }

  List<String> _observabilityGaps(List<DepartmentSummary> summaries) {
    final categories = <String>{};

    for (final summary in summaries) {
      for (final signal in summary.missingOperationalData) {
        final category = observabilityCategories[signal];
        if (category != null) {
          categories.add(category);
        }
      }
    }

    final sorted = categories.toList()..sort();

    return sorted;
  }
}
