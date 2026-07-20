import 'package:pharos_ai_runtime/knowledge/fact_type.dart';
import 'package:pharos_ai_runtime/operations/operational_state.dart';
import 'package:pharos_ai_runtime/operations/state_completeness.dart';
import 'package:test/test.dart';

OperationalState _state(Map<String, SignalState> signals) => OperationalState(
  factId: 'website:petsupo.com',
  factType: FactType.website,
  name: 'petsupo.com',
  signals: signals,
);

void main() {
  test('calculate() returns 1.0 when every signal is known', () {
    const completeness = StateCompleteness();

    final score = completeness.calculate(
      _state({'exists': SignalState.yes, 'configured': SignalState.yes}),
    );

    expect(score, 1.0);
  });

  test('calculate() returns 0.0 when every signal is unknown', () {
    const completeness = StateCompleteness();

    final score = completeness.calculate(
      _state({
        'reachable': SignalState.unknown,
        'lastDeploy': SignalState.unknown,
      }),
    );

    expect(score, 0.0);
  });

  test('calculate() counts a known-No signal as known, not as unknown', () {
    const completeness = StateCompleteness();

    final score = completeness.calculate(
      _state({
        'exists': SignalState.yes,
        'trafficMetricsAvailable': SignalState.no,
        'reachable': SignalState.unknown,
        'lastDeploy': SignalState.unknown,
      }),
    );

    expect(score, 0.5);
  });

  test('calculate() returns 0.0 for a state with no signals', () {
    const completeness = StateCompleteness();

    final score = completeness.calculate(_state(const {}));

    expect(score, 0.0);
  });

  test('calculate() is deterministic', () {
    const completeness = StateCompleteness();
    final state = _state({
      'exists': SignalState.yes,
      'reachable': SignalState.unknown,
    });

    expect(completeness.calculate(state), completeness.calculate(state));
  });
}
