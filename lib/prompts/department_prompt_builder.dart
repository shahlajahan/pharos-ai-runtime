import 'package:pharos_ai_runtime/company/department_facts.dart';
import 'package:pharos_ai_runtime/knowledge/company_fact.dart';
import 'package:pharos_ai_runtime/knowledge/fact_type.dart';

/// Builds the grounded prompt sent to the LLM for one Department, and
/// composes every department's prompt into the single request DailyAgent
/// sends for the full daily plan. The prompt receives only structured
/// CompanyFacts — never raw HQ markdown. Pure and deterministic: the
/// same DepartmentFacts and date always produce the same prompt.
class DepartmentPromptBuilder {
  const DepartmentPromptBuilder();

  String build({
    required DepartmentFacts departmentFacts,
    required DateTime currentDate,
  }) {
    final department = departmentFacts.department.displayName;

    final buffer = StringBuffer()
      ..writeln('$department Facts:')
      ..write(_renderFacts(departmentFacts.facts))
      ..writeln(
        'Missing Facts: ${_joinTypesOrNone(departmentFacts.missingTypes)}',
      )
      ..writeln()
      ..writeln('Reasoning Goal:')
      ..writeln(
        "Using ONLY the $department Facts above, write today's "
        '$department Priorities: a short, concrete, actionable list. '
        'Every recommendation must cite the CompanyFact type(s) it is '
        'based on as Evidence, and state a Confidence level (High, '
        'Medium, or Low). Never invent facts, KPIs, campaigns, or '
        'business metrics. Never make a recommendation without evidence. '
        'If a Missing Fact would be required to make a specific '
        'recommendation, explicitly say so instead of guessing.',
      );

    return buffer.toString();
  }

  /// Composes every department's prompt into the single request sent for
  /// the full daily plan, in a fixed department order.
  String buildReport({
    required List<DepartmentFacts> departmentFacts,
    required DateTime currentDate,
  }) {
    final buffer = StringBuffer()
      ..writeln("You are preparing today's Pharos Executive Plan.")
      ..writeln()
      ..writeln('Current date: ${currentDate.toIso8601String()}')
      ..writeln()
      ..writeln('Rules:')
      ..writeln('- Reason only over the Department Facts below.')
      ..writeln('- Never invent company facts.')
      ..writeln('- Never invent KPIs.')
      ..writeln('- Never invent campaigns.')
      ..writeln('- Never invent business metrics.')
      ..writeln('- Never classify documents or discover products yourself.')
      ..writeln(
        '- If information is unavailable, explicitly state that it is '
        'unavailable rather than guessing.',
      )
      ..writeln(
        '- Distinguish clearly between Known, Missing, and Recommendation.',
      )
      ..writeln();

    for (final facts in departmentFacts) {
      buffer
        ..writeln(build(departmentFacts: facts, currentDate: currentDate))
        ..writeln();
    }

    buffer.writeln(
      "Using ONLY the Department Facts above, write today's Executive "
      'Plan with exactly one heading per department, in this order:',
    );

    for (final facts in departmentFacts) {
      buffer.writeln("Today's ${facts.department.displayName} Priorities");
    }

    buffer
      ..writeln()
      ..writeln(
        'Do not include Blocked Items, Missing Facts, or Recommended Next '
        'Connections sections — the Runtime appends them automatically.',
      );

    return buffer.toString();
  }

  String _renderFacts(List<CompanyFact> facts) {
    final buffer = StringBuffer()..writeln('Facts:');

    if (facts.isEmpty) {
      buffer.writeln('- None known.');
    } else {
      for (final fact in facts) {
        buffer.writeln('- ${fact.type.displayName}: ${fact.name}');
      }
    }

    return buffer.toString();
  }

  String _joinTypesOrNone(List<FactType> types) =>
      types.isEmpty ? 'None' : types.map((type) => type.displayName).join(', ');
}
