import 'package:pharos_ai_runtime/company/department.dart';
import 'package:pharos_ai_runtime/knowledge/fact_type.dart';
import 'package:pharos_ai_runtime/operations/operational_snapshot.dart';
import 'package:pharos_ai_runtime/operations/operational_state.dart';
import 'package:pharos_ai_runtime/prompts/department_prompt_builder.dart';
import 'package:test/test.dart';

OperationalState _allowedState() => const OperationalState(
  factId: 'brand-asset:Brand Kit',
  factType: FactType.brandAsset,
  name: 'Brand Kit',
  signals: {'exists': SignalState.yes},
);

OperationalState _blockedState() => const OperationalState(
  factId: 'website:petsupo.com',
  factType: FactType.website,
  name: 'petsupo.com',
  signals: {
    'exists': SignalState.yes,
    'reachable': SignalState.unknown,
    'analyticsConnected': SignalState.no,
    'trafficMetricsAvailable': SignalState.no,
    'lastDeploy': SignalState.unknown,
  },
);

OperationalSnapshot _snapshot(Department department) => OperationalSnapshot(
  department: department,
  states: [_allowedState(), _blockedState()],
  allowed: [_allowedState()],
  blocked: [
    BlockedRecommendation(
      state: _blockedState(),
      missingSignals: const ['reachable', 'lastDeploy'],
      confidence: 'Low',
    ),
  ],
  observabilityScore: 0.7,
  missingOperationalData: const ['reachable', 'lastDeploy'],
);

void main() {
  test('build() generates identical prompts for identical OperationalSnapshots '
      'and dates', () {
    const builder = DepartmentPromptBuilder();
    final date = DateTime(2026, 7, 20);

    final first = builder.build(
      snapshot: _snapshot(Department.marketing),
      currentDate: date,
    );
    final second = builder.build(
      snapshot: _snapshot(Department.marketing),
      currentDate: date,
    );

    expect(first, second);
  });

  test('build() renders Known Facts, Operational State, Missing Operational '
      'Data, allowed, and blocked sections — never a raw markdown excerpt '
      'or filesystem path', () {
    const builder = DepartmentPromptBuilder();

    final prompt = builder.build(
      snapshot: _snapshot(Department.marketing),
      currentDate: DateTime(2026, 7, 20),
    );

    expect(prompt, contains('Marketing Known Facts:'));
    expect(prompt, contains('Brand Asset: Brand Kit'));
    expect(prompt, contains('Marketing Operational State:'));
    expect(prompt, contains('reachable=Unknown'));
    expect(prompt, contains('trafficMetricsAvailable=No'));
    expect(prompt, contains('Missing Operational Data: reachable, lastDeploy'));
    expect(prompt, contains('Allowed for action recommendations: Brand Kit'));
    expect(prompt, contains('Blocked (insufficient evidence): petsupo.com'));
    expect(prompt, isNot(contains('.md')));
    expect(prompt, isNot(contains('products/')));
  });

  test('build() instructs the LLM never to recommend action on a blocked '
      'entity, and to state confidence for allowed ones', () {
    const builder = DepartmentPromptBuilder();

    final prompt = builder.build(
      snapshot: _snapshot(Department.engineering),
      currentDate: DateTime(2026, 7, 20),
    );

    expect(prompt, contains('must NOT recommend an action about it'));
    expect(prompt, contains('recommend improving observability instead'));
    expect(prompt, contains('must state a Confidence level'));
  });

  test('buildReport() composes one Known Facts / Operational State section '
      'per department, in order', () {
    const builder = DepartmentPromptBuilder();
    final snapshots = Department.values.map(_snapshot).toList();

    final report = builder.buildReport(
      operationalSnapshots: snapshots,
      currentDate: DateTime(2026, 7, 20),
    );

    for (final department in Department.values) {
      expect(report, contains('${department.displayName} Known Facts:'));
      expect(report, contains("Today's ${department.displayName} Priorities"));
    }
  });

  test('buildReport() instructs the model not to render Runtime-owned '
      'sections', () {
    const builder = DepartmentPromptBuilder();

    final report = builder.buildReport(
      operationalSnapshots: [_snapshot(Department.finance)],
      currentDate: DateTime(2026, 7, 20),
    );

    expect(report, contains('Blocked Items'));
    expect(report, contains('Missing Operational Data'));
    expect(report, contains('Runtime appends'));
  });

  test('buildReport() includes the current date', () {
    const builder = DepartmentPromptBuilder();

    final report = builder.buildReport(
      operationalSnapshots: [_snapshot(Department.sales)],
      currentDate: DateTime(2026, 7, 20),
    );

    expect(report, contains('2026-07-20'));
  });
}
