import 'package:pharos_ai_runtime/priorities/department_summary.dart';
import 'package:pharos_ai_runtime/priorities/executive_summary.dart';

/// Builds the single prompt DailyAgent sends the LLM. Per the Prompt
/// Contract, the LLM receives only the Executive Summary, Department
/// Summaries, Top Decisions, Blocked Decisions, Health Scores, and
/// Observability Gaps — nothing else: no CompanyDocuments, no raw
/// markdown, no filesystem paths, and no departmental decisions in
/// isolation. Pure and deterministic: the same ExecutiveSummary and date
/// always produce the same prompt.
class DepartmentPromptBuilder {
  const DepartmentPromptBuilder();

  String buildReport({
    required ExecutiveSummary summary,
    required DateTime currentDate,
  }) {
    final buffer = StringBuffer()
      ..writeln("You are preparing today's Pharos Executive Brief.")
      ..writeln()
      ..writeln('Current date: ${currentDate.toIso8601String()}')
      ..writeln()
      ..writeln('Rules:')
      ..writeln(
        '- Reason only over the Executive Summary below — you are a '
        'communication layer, not the decision maker.',
      )
      ..writeln(
        '- The Runtime already aggregated every department\'s decisions; '
        'do not invent, reorder, merge, or add a decision, and do not '
        'calculate your own priority or health score.',
      )
      ..writeln(
        '- Never invent company facts, KPIs, campaigns, or business metrics.',
      )
      ..writeln(
        '- Never recommend action on an item listed under Blocked '
        'Decisions; state why it is blocked instead.',
      )
      ..writeln()
      ..writeln('Executive Summary:')
      ..writeln('Company Health: ${_percentage(summary.companyHealth)}%')
      ..writeln('Top Decisions: ${summary.topDecisions.length}')
      ..writeln('Blocked Decisions: ${summary.blockedDecisions.length}')
      ..writeln()
      ..writeln('Department Summaries:')
      ..write(_renderDepartmentSummaries(summary.departmentSummaries))
      ..writeln('Health Scores:')
      ..write(_renderHealthScores(summary))
      ..writeln('Top Decisions:')
      ..write(_renderMergedDecisions(summary.topDecisions))
      ..writeln('Blocked Decisions:')
      ..write(_renderMergedDecisions(summary.blockedDecisions))
      ..writeln('Observability Gaps: ${_joinOrNone(summary.observabilityGaps)}')
      ..writeln()
      ..writeln(
        "Using ONLY the information above, write today's Executive Brief: "
        'a short Company Health statement, then explain each Top '
        'Decision (citing its Evidence and Confidence) and each Blocked '
        'Decision (stating why it is blocked), and close with the '
        'Observability Gaps as a dashboard, never as "Connect X" '
        'recommendations.',
      );

    return buffer.toString();
  }

  String _renderDepartmentSummaries(List<DepartmentSummary> summaries) {
    final buffer = StringBuffer();

    if (summaries.isEmpty) {
      buffer.writeln('- None.');
      return buffer.toString();
    }

    for (final summary in summaries) {
      buffer.writeln(
        '- ${summary.department.displayName}: '
        'Decision Count: ${summary.decisionCount}, '
        'Blocked Count: ${summary.blockedCount}, '
        'Observability: ${_percentage(summary.observability)}%, '
        'Readiness: ${_percentage(summary.readiness)}%, '
        'Health: ${_percentage(summary.health)}%',
      );
    }

    return buffer.toString();
  }

  String _renderHealthScores(ExecutiveSummary summary) {
    final buffer = StringBuffer()
      ..writeln('- Company: ${_percentage(summary.companyHealth)}%');

    for (final department in summary.departmentSummaries) {
      buffer.writeln(
        '- ${department.department.displayName}: '
        '${_percentage(department.health)}%',
      );
    }

    return buffer.toString();
  }

  String _renderMergedDecisions(List<MergedDecision> merged) {
    final buffer = StringBuffer();

    if (merged.isEmpty) {
      buffer.writeln('- None.');
      return buffer.toString();
    }

    for (final entry in merged) {
      final decision = entry.decision;
      final affects = entry.affects.map((d) => d.displayName).join(', ');
      final reasons = decision.reasons.map((r) => r.statement).join('; ');
      final evidence = decision.evidence
          .map((type) => type.displayName)
          .join(', ');

      buffer.writeln(
        '- ${decision.title} [Affects: $affects, Priority: '
        '${decision.priority.name}, Impact: '
        '${decision.score.impact.toStringAsFixed(2)}, Urgency: '
        '${decision.score.urgency.toStringAsFixed(2)}, Confidence: '
        '${decision.confidence.toStringAsFixed(2)}] Reasons: $reasons. '
        'Evidence: $evidence.',
      );
    }

    return buffer.toString();
  }

  String _percentage(double value) => (value * 100).round().toString();

  String _joinOrNone(List<String> entries) =>
      entries.isEmpty ? 'None' : entries.join(', ');
}
