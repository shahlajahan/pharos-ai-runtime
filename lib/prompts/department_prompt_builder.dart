import 'package:pharos_ai_runtime/company/department_snapshot.dart';

/// Builds the grounded prompt sent to the LLM for one Department, and
/// composes every department's prompt into the single request DailyAgent
/// sends for the full daily plan. Pure and deterministic: the same
/// DepartmentSnapshots and date always produce the same prompt.
class DepartmentPromptBuilder {
  const DepartmentPromptBuilder();

  String build({
    required DepartmentSnapshot snapshot,
    required DateTime currentDate,
  }) {
    final department = snapshot.department.displayName;

    final buffer = StringBuffer()
      ..writeln('$department Snapshot:')
      ..write(_renderSection('Company', snapshot.company))
      ..write(_renderSection('Knowledge', snapshot.knowledge))
      ..write(_renderSection('Products', snapshot.products))
      ..write(_renderSection('Assets', snapshot.assets))
      ..write(_renderSection('Services', snapshot.services))
      ..write(_renderSection('Websites', snapshot.websites))
      ..write(_renderSection('Social', snapshot.social))
      ..write(_renderSection('Analytics', snapshot.analytics))
      ..writeln('Known Data: ${_joinOrNone(snapshot.knownData)}')
      ..writeln('Missing Data: ${_joinOrNone(snapshot.missingData)}')
      ..writeln()
      ..writeln(
        "Using ONLY the $department Snapshot above, write today's "
        '$department Priorities: a short, concrete, actionable list. '
        'Never invent facts, KPIs, campaigns, or business metrics. '
        'Distinguish clearly between what is known and what is a '
        'recommendation. If there is not enough evidence to recommend '
        'something specific, explicitly say so instead of guessing.',
      );

    return buffer.toString();
  }

  /// Composes every department's prompt into the single request sent for
  /// the full daily plan, in a fixed department order.
  String buildReport({
    required List<DepartmentSnapshot> snapshots,
    required DateTime currentDate,
  }) {
    final buffer = StringBuffer()
      ..writeln("You are preparing today's Pharos Company Plan.")
      ..writeln()
      ..writeln('Current date: ${currentDate.toIso8601String()}')
      ..writeln()
      ..writeln('Rules:')
      ..writeln('- Reason only over the Department Snapshots below.')
      ..writeln('- Never invent company facts.')
      ..writeln('- Never invent KPIs.')
      ..writeln('- Never invent campaigns.')
      ..writeln('- Never invent business metrics.')
      ..writeln(
        '- If information is unavailable, explicitly state that it is '
        'unavailable rather than guessing.',
      )
      ..writeln(
        '- Distinguish clearly between Known, Unknown, and Recommendation.',
      )
      ..writeln();

    for (final snapshot in snapshots) {
      buffer
        ..writeln(build(snapshot: snapshot, currentDate: currentDate))
        ..writeln();
    }

    buffer.writeln(
      "Using ONLY the Department Snapshots above, write today's Company "
      'Plan with exactly one heading per department, in this order:',
    );

    for (final snapshot in snapshots) {
      buffer.writeln("Today's ${snapshot.department.displayName} Priorities");
    }

    buffer
      ..writeln()
      ..writeln(
        'Do not include Blocked Items, Missing Data, or Recommended Next '
        'Connections sections — the Runtime appends them automatically.',
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
