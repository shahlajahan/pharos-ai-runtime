import 'package:pharos_ai_runtime/operations/operational_state.dart';
import 'package:pharos_ai_runtime/operations/state_completeness.dart';

/// Whether an OperationalState carries enough evidence to allow an
/// action-level recommendation, or whether the Runtime must instead
/// steer the LLM toward recommending better observability first.
class DecisionGateResult {
  const DecisionGateResult({
    required this.allowed,
    required this.missingSignals,
    required this.completeness,
    required this.confidence,
  });

  final bool allowed;

  /// Signal names still [SignalState.unknown] — the reason a state is
  /// blocked, when it is.
  final List<String> missingSignals;
  final double completeness;

  /// 'High', 'Medium', or 'Low', derived from [completeness].
  final String confidence;
}

/// The gate every OperationalState passes through before it may support
/// an action-level recommendation. Facts alone must never generate
/// recommendations: a state is only [DecisionGateResult.allowed] when
/// every one of its readiness signals is known, not merely present.
class DecisionGate {
  const DecisionGate({
    StateCompleteness completeness = const StateCompleteness(),
  }) : _completeness = completeness;

  final StateCompleteness _completeness;

  DecisionGateResult evaluate(OperationalState state) {
    final score = _completeness.calculate(state);
    final missingSignals = [
      for (final entry in state.signals.entries)
        if (entry.value == SignalState.unknown) entry.key,
    ];

    return DecisionGateResult(
      allowed: missingSignals.isEmpty,
      missingSignals: missingSignals,
      completeness: score,
      confidence: _confidenceFor(score),
    );
  }

  String _confidenceFor(double score) {
    if (score >= 0.75) return 'High';
    if (score >= 0.4) return 'Medium';
    return 'Low';
  }
}
