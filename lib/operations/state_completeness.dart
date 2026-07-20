import 'package:pharos_ai_runtime/operations/operational_state.dart';

/// Scores how much is actually known about one OperationalState, as the
/// fraction of its signals that are not [SignalState.unknown].
/// Deterministic: no AI, no heuristics beyond a straight count.
class StateCompleteness {
  const StateCompleteness();

  double calculate(OperationalState state) {
    if (state.signals.isEmpty) {
      return 0.0;
    }

    final known = state.signals.values
        .where((signal) => signal != SignalState.unknown)
        .length;

    return known / state.signals.length;
  }
}
