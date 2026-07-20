import 'package:pharos_ai_runtime/operations/operational_snapshot.dart';
import 'package:pharos_ai_runtime/operations/operational_state.dart';

/// Builds the grounded prompt sent to the LLM for one Department, and
/// composes every department's prompt into the single request DailyAgent
/// sends for the full daily plan. Per the Prompt Contract, the LLM
/// receives only Known Facts, Operational State, Missing Operational
/// Data, and a Decision Goal — never raw HQ markdown, filesystem paths,
/// or CompanyDocuments. Pure and deterministic: the same
/// OperationalSnapshots and date always produce the same prompt.
class DepartmentPromptBuilder {
  const DepartmentPromptBuilder();

  String build({
    required OperationalSnapshot snapshot,
    required DateTime currentDate,
  }) {
    final department = snapshot.department.displayName;

    final buffer = StringBuffer()
      ..writeln('$department Known Facts:')
      ..write(_renderKnownFacts(snapshot.states))
      ..writeln('$department Operational State:')
      ..write(_renderOperationalState(snapshot.states))
      ..writeln(
        'Missing Operational Data: '
        '${_joinOrNone(snapshot.missingOperationalData)}',
      )
      ..writeln(
        'Observability Score: '
        '${snapshot.observabilityScore.toStringAsFixed(2)}',
      )
      ..writeln(
        'Allowed for action recommendations: '
        '${_joinNamesOrNone(snapshot.allowed.map((s) => s.name).toList())}',
      )
      ..writeln(
        'Blocked (insufficient evidence): '
        '${_renderBlocked(snapshot)}',
      )
      ..writeln()
      ..writeln('Decision Goal:')
      ..writeln(
        "Using ONLY the $department Known Facts and Operational State "
        "above, write today's $department Priorities: a short, concrete, "
        'list. For an entity listed as "Allowed for action '
        'recommendations", you may recommend a concrete next action and '
        'must state a Confidence level matching its evidence. For an '
        'entity listed as "Blocked (insufficient evidence)", you must '
        'NOT recommend an action about it — recommend improving '
        'observability instead (naming the missing operational data), '
        'never guess the missing evidence. Every recommendation must '
        'cite the fact type and entity name it is based on as Evidence. '
        'Never invent facts, KPIs, campaigns, or business metrics.',
      );

    return buffer.toString();
  }

  /// Composes every department's prompt into the single request sent for
  /// the full daily plan, in a fixed department order.
  String buildReport({
    required List<OperationalSnapshot> operationalSnapshots,
    required DateTime currentDate,
  }) {
    final buffer = StringBuffer()
      ..writeln("You are preparing today's Pharos Executive Plan.")
      ..writeln()
      ..writeln('Current date: ${currentDate.toIso8601String()}')
      ..writeln()
      ..writeln('Rules:')
      ..writeln('- Reason only over the Operational State below.')
      ..writeln(
        '- A fact existing is not evidence of readiness — only act on '
        'entities marked "Allowed for action recommendations".',
      )
      ..writeln('- Never invent company facts.')
      ..writeln('- Never invent KPIs.')
      ..writeln('- Never invent campaigns.')
      ..writeln('- Never invent business metrics.')
      ..writeln(
        '- If information is unavailable, explicitly state that it is '
        'unavailable rather than guessing.',
      )
      ..writeln(
        '- Distinguish clearly between Known, Missing, and Recommendation.',
      )
      ..writeln();

    for (final snapshot in operationalSnapshots) {
      buffer
        ..writeln(build(snapshot: snapshot, currentDate: currentDate))
        ..writeln();
    }

    buffer.writeln(
      "Using ONLY the Operational State above, write today's Executive "
      'Plan with exactly one heading per department, in this order:',
    );

    for (final snapshot in operationalSnapshots) {
      buffer.writeln("Today's ${snapshot.department.displayName} Priorities");
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

  String _renderKnownFacts(List<OperationalState> states) {
    final buffer = StringBuffer()..writeln('Facts:');

    if (states.isEmpty) {
      buffer.writeln('- None known.');
    } else {
      for (final state in states) {
        buffer.writeln('- ${state.factType.displayName}: ${state.name}');
      }
    }

    return buffer.toString();
  }

  String _renderOperationalState(List<OperationalState> states) {
    final buffer = StringBuffer()..writeln('State:');

    if (states.isEmpty) {
      buffer.writeln('- None known.');
    } else {
      for (final state in states) {
        final signals = state.signals.entries
            .map((entry) => '${entry.key}=${_signalLabel(entry.value)}')
            .join(', ');
        buffer.writeln(
          '- ${state.name} (${state.factType.displayName}): $signals',
        );
      }
    }

    return buffer.toString();
  }

  String _renderBlocked(OperationalSnapshot snapshot) {
    if (snapshot.blocked.isEmpty) {
      return 'None';
    }

    return snapshot.blocked
        .map(
          (blocked) =>
              '${blocked.state.name} (missing: '
              '${blocked.missingSignals.join(', ')}; confidence: '
              '${blocked.confidence})',
        )
        .join('; ');
  }

  String _signalLabel(SignalState signal) => switch (signal) {
    SignalState.yes => 'Yes',
    SignalState.no => 'No',
    SignalState.unknown => 'Unknown',
  };

  String _joinOrNone(List<String> entries) =>
      entries.isEmpty ? 'None' : entries.join(', ');

  String _joinNamesOrNone(List<String> names) =>
      names.isEmpty ? 'None' : names.join(', ');
}
