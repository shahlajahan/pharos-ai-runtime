import 'package:pharos_ai_runtime/company/department.dart';
import 'package:pharos_ai_runtime/decision/decision.dart';
import 'package:pharos_ai_runtime/priorities/department_summary.dart';

/// One or more identical decisions raised independently by different
/// departments, merged into a single company-level entry. Instead of
/// showing "Connect GA4" twice, the Executive sees it once, with
/// [affects] naming every department it was raised by.
class MergedDecision {
  const MergedDecision({required this.decision, required this.affects});

  /// The highest-scoring decision among the duplicates — used for its
  /// title, priority, score, reasons, and evidence.
  final Decision decision;

  final List<Department> affects;
}

/// The Executive's aggregated view of the whole company: never
/// departmental decisions in isolation, only the highest-value work
/// across every department. ExecutiveAggregator builds this by
/// aggregating existing DepartmentSummaries — it never invents new
/// work.
class ExecutiveSummary {
  const ExecutiveSummary({
    required this.companyHealth,
    required this.topDecisions,
    required this.blockedDecisions,
    required this.observabilityGaps,
    required this.departmentSummaries,
  });

  /// The average department health across the whole company, 0.0-1.0.
  final double companyHealth;

  /// At most 3 (see PriorityEngine.topCount), merged and ranked across
  /// every department.
  final List<MergedDecision> topDecisions;

  /// At most 3, merged and ranked across every department.
  final List<MergedDecision> blockedDecisions;

  /// Dashboard-level categories with missing data (for example
  /// "Analytics", "Social Metrics") — never the raw signal names or
  /// "Connect X" recommendations; those are implementation details the
  /// Executive should never see.
  final List<String> observabilityGaps;

  final List<DepartmentSummary> departmentSummaries;
}
