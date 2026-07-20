import 'package:pharos_ai_runtime/company/department.dart';
import 'package:pharos_ai_runtime/decision/decision.dart';
import 'package:pharos_ai_runtime/decision/decision_engine.dart';

/// Builds the grounded prompt sent to the LLM for one Department, and
/// composes every department's prompt into the single request DailyAgent
/// sends for the full daily brief. Per the Prompt Contract, the LLM
/// receives only Top Decisions, Blockers, Informational Notes, Evidence,
/// and Decision Scores — never raw HQ markdown, filesystem paths, or
/// CompanyDocuments, and it never calculates priority itself. Pure and
/// deterministic: the same Decisions and date always produce the same
/// prompt.
class DepartmentPromptBuilder {
  const DepartmentPromptBuilder();

  String build({
    required Department department,
    required List<Decision> decisions,
    required DateTime currentDate,
  }) {
    final blockers = decisions.where((d) => d.blocked).toList();
    final priorities = decisions
        .where((d) => !d.blocked && DecisionEngine.isActionable(d.type))
        .toList();
    final informational = decisions
        .where((d) => !d.blocked && !DecisionEngine.isActionable(d.type))
        .toList();
    final name = department.displayName;

    final buffer = StringBuffer()
      ..writeln('$name Top Decisions:')
      ..write(_renderDecisions(priorities))
      ..writeln('$name Blockers:')
      ..write(_renderDecisions(blockers))
      ..writeln('$name Informational Notes:')
      ..write(_renderDecisions(informational))
      ..writeln()
      ..writeln('Decision Goal:')
      ..writeln(
        'Using ONLY the $name Top Decisions, Blockers, Informational '
        'Notes, Evidence, and Decision Scores above, explain each in '
        'short, natural, executive-ready prose. The Runtime already '
        'determined priority order, impact, urgency, and confidence — '
        'do not invent, reorder, merge, or add decisions, and do not '
        'calculate your own priority. Never recommend action on an item '
        'listed under Blockers; state why it is blocked instead. Cite '
        'only the Evidence already listed for each decision.',
      );

    return buffer.toString();
  }

  /// Composes every department's prompt into the single request sent for
  /// the full daily brief, in a fixed department order.
  String buildReport({
    required Map<Department, List<Decision>> decisionsByDepartment,
    required DateTime currentDate,
  }) {
    final buffer = StringBuffer()
      ..writeln("You are preparing today's Pharos Executive Brief.")
      ..writeln()
      ..writeln('Current date: ${currentDate.toIso8601String()}')
      ..writeln()
      ..writeln('Rules:')
      ..writeln(
        '- Reason only over the Decisions below — you are a '
        'communication layer, not the decision maker.',
      )
      ..writeln('- Never invent company facts.')
      ..writeln('- Never invent KPIs.')
      ..writeln('- Never invent campaigns.')
      ..writeln('- Never invent business metrics.')
      ..writeln('- Never invent a Decision, priority, or score.')
      ..writeln(
        '- If information is unavailable, explicitly state that it is '
        'unavailable rather than guessing.',
      )
      ..writeln();

    for (final department in Department.values) {
      final decisions = decisionsByDepartment[department] ?? const <Decision>[];
      buffer
        ..writeln(
          build(
            department: department,
            decisions: decisions,
            currentDate: currentDate,
          ),
        )
        ..writeln();
    }

    buffer.writeln(
      "Using ONLY the Decisions above, write today's Executive Brief "
      'with exactly one heading per department, in this order:',
    );

    for (final department in Department.values) {
      buffer.writeln("Today's ${department.displayName} Priorities");
    }

    buffer
      ..writeln()
      ..writeln(
        'Do not include Blocked Items, Missing Operational Data, or '
        'Recommended Next Connections sections — the Runtime appends '
        'them automatically.',
      );

    return buffer.toString();
  }

  String _renderDecisions(List<Decision> decisions) {
    final buffer = StringBuffer();

    if (decisions.isEmpty) {
      buffer.writeln('- None.');
      return buffer.toString();
    }

    for (final decision in decisions) {
      final reasons = decision.reasons.map((r) => r.statement).join('; ');
      final evidence = decision.evidence
          .map((type) => type.displayName)
          .join(', ');

      buffer.writeln(
        '- ${decision.title} [Priority: ${decision.priority.name}, '
        'Impact: ${decision.score.impact.toStringAsFixed(2)}, '
        'Urgency: ${decision.score.urgency.toStringAsFixed(2)}, '
        'Confidence: ${decision.confidence.toStringAsFixed(2)}] '
        'Reasons: $reasons. Evidence: $evidence.',
      );
    }

    return buffer.toString();
  }
}
