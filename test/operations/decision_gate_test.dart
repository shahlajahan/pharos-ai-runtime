import 'package:pharos_ai_runtime/knowledge/fact_type.dart';
import 'package:pharos_ai_runtime/operations/decision_gate.dart';
import 'package:pharos_ai_runtime/operations/operational_state.dart';
import 'package:test/test.dart';

OperationalState _state(Map<String, SignalState> signals) => OperationalState(
  factId: 'website:petsupo.com',
  factType: FactType.website,
  name: 'petsupo.com',
  signals: signals,
);

void main() {
  test('evaluate() allows a state when every signal is known (Allowed: '
      'existence-only entities such as Product, BrandAsset, MediaAsset)', () {
    const gate = DecisionGate();

    final result = gate.evaluate(_state({'exists': SignalState.yes}));

    expect(result.allowed, isTrue);
    expect(result.missingSignals, isEmpty);
  });

  test('evaluate() blocks a state with any unknown signal (Blocked: Website '
      'exists but Analytics evidence is missing)', () {
    const gate = DecisionGate();

    final result = gate.evaluate(
      _state({
        'exists': SignalState.yes,
        'reachable': SignalState.unknown,
        'analyticsConnected': SignalState.no,
      }),
    );

    expect(result.allowed, isFalse);
    expect(result.missingSignals, ['reachable']);
  });

  test('evaluate() blocks Instagram-style states until engagement metrics '
      'are known', () {
    const gate = DecisionGate();

    final result = gate.evaluate(
      _state({
        'exists': SignalState.yes,
        'engagement': SignalState.unknown,
        'insightsConnected': SignalState.no,
      }),
    );

    expect(result.allowed, isFalse);
    expect(result.missingSignals, contains('engagement'));
  });

  test('evaluate() blocks GA4-style states until traffic data is known', () {
    const gate = DecisionGate();

    final result = gate.evaluate(
      _state({
        'exists': SignalState.yes,
        'configured': SignalState.yes,
        'liveMetricsAvailable': SignalState.no,
        'lastSync': SignalState.unknown,
      }),
    );

    expect(result.allowed, isFalse);
    expect(result.missingSignals, ['lastSync']);
  });

  test('evaluate() reports every unknown signal, not just the first', () {
    const gate = DecisionGate();

    final result = gate.evaluate(
      _state({
        'exists': SignalState.yes,
        'reachable': SignalState.unknown,
        'lastDeploy': SignalState.unknown,
      }),
    );

    expect(result.missingSignals, ['reachable', 'lastDeploy']);
  });

  test('evaluate() scales confidence with completeness: 0.93-equivalent '
      'completeness yields High', () {
    const gate = DecisionGate();

    final result = gate.evaluate(
      _state({
        'a': SignalState.yes,
        'b': SignalState.yes,
        'c': SignalState.yes,
        'd': SignalState.unknown,
      }),
    );

    expect(result.confidence, 'High');
  });

  test('evaluate() scales confidence with completeness: 0.25-equivalent '
      'completeness yields Low', () {
    const gate = DecisionGate();

    final result = gate.evaluate(
      _state({
        'a': SignalState.yes,
        'b': SignalState.unknown,
        'c': SignalState.unknown,
        'd': SignalState.unknown,
      }),
    );

    expect(result.confidence, 'Low');
  });

  test('evaluate() yields Medium confidence for middling completeness', () {
    const gate = DecisionGate();

    final result = gate.evaluate(
      _state({
        'a': SignalState.yes,
        'b': SignalState.yes,
        'c': SignalState.unknown,
        'd': SignalState.unknown,
      }),
    );

    expect(result.confidence, 'Medium');
  });

  test('evaluate() is deterministic', () {
    const gate = DecisionGate();
    final state = _state({'exists': SignalState.yes});

    final first = gate.evaluate(state);
    final second = gate.evaluate(state);

    expect(first.allowed, second.allowed);
    expect(first.confidence, second.confidence);
  });
}
