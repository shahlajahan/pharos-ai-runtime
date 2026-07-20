import 'package:pharos_ai_runtime/company/company_snapshot.dart';

/// Builds the single prompt the Daily Agent sends to the LLM. Prompt
/// generation lives here, never inline inside DailyAgent, so it stays
/// reusable and independently testable. Pure and deterministic: the
/// same CompanySnapshot, current date, and workflow goal always produce
/// the exact same prompt.
class DailyPromptBuilder {
  const DailyPromptBuilder();

  String build({
    required CompanySnapshot snapshot,
    required DateTime currentDate,
    required String workflowGoal,
  }) {
    final buffer = StringBuffer()
      ..writeln("You are preparing today's Pharos Executive Daily Report.")
      ..writeln()
      ..writeln('Current date: ${currentDate.toIso8601String()}')
      ..writeln('Workflow goal: $workflowGoal')
      ..writeln()
      ..writeln('Rules:')
      ..writeln('- Reason only over the Company Snapshot below.')
      ..writeln('- Never invent company facts.')
      ..writeln('- Never invent KPIs.')
      ..writeln('- Never invent campaigns.')
      ..writeln('- Never invent analytics.')
      ..writeln('- Never invent revenue.')
      ..writeln(
        '- If information is unavailable, explicitly state that it is '
        'unavailable.',
      )
      ..writeln(
        '- Distinguish clearly between Known, Unknown, and '
        'Recommendation.',
      )
      ..writeln()
      ..writeln('Company Snapshot:')
      ..write(_renderSection('Company', snapshot.company))
      ..write(_renderSection('Products', snapshot.products))
      ..write(_renderSection('Capabilities', snapshot.capabilities))
      ..write(_renderSection('Assets', snapshot.assets))
      ..write(_renderSection('Websites', snapshot.websites))
      ..write(_renderSection('Analytics', snapshot.analytics))
      ..write(_renderSection('Social Platforms', snapshot.social))
      ..write(_renderSection('Services', snapshot.services))
      ..writeln('Known Data: ${_joinOrNone(snapshot.knownData)}')
      ..writeln('Missing Data: ${_joinOrNone(snapshot.missingData)}')
      ..write(_renderSection('Risks', snapshot.risks))
      ..write(
        _renderSection('Recommendations Input', snapshot.recommendationsInput),
      )
      ..writeln()
      ..writeln(
        "Using ONLY the information above, write today's Executive Daily "
        'Report with exactly these sections, each as its own heading, '
        'in this order:',
      )
      ..writeln('Executive Summary')
      ..writeln('Company Snapshot')
      ..writeln('Products')
      ..writeln('Business Assets')
      ..writeln('Current Capabilities')
      ..writeln('Known Information')
      ..writeln('Missing Information')
      ..writeln("Today's Priorities")
      ..writeln('Recommended Next Actions')
      ..writeln()
      ..writeln(
        'Do not include a "Data Sources Used" section — the Runtime '
        'appends it automatically.',
      );

    return buffer.toString();
  }

  String _renderSection(String title, List<String> entries) {
    final buffer = StringBuffer()..writeln('$title:');

    if (entries.isEmpty) {
      buffer.writeln('- Not yet connected.');
    } else {
      for (final entry in entries) {
        buffer.writeln('- $entry');
      }
    }

    return buffer.toString();
  }

  String _joinOrNone(List<String> entries) =>
      entries.isEmpty ? 'None' : entries.join(', ');
}
