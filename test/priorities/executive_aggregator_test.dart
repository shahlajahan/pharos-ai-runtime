import 'package:pharos_ai_runtime/company/department.dart';
import 'package:pharos_ai_runtime/decision/decision.dart';
import 'package:pharos_ai_runtime/decision/decision_priority.dart';
import 'package:pharos_ai_runtime/decision/decision_reason.dart';
import 'package:pharos_ai_runtime/decision/decision_score.dart';
import 'package:pharos_ai_runtime/decision/decision_type.dart';
import 'package:pharos_ai_runtime/knowledge/fact_type.dart';
import 'package:pharos_ai_runtime/priorities/department_summary.dart';
import 'package:pharos_ai_runtime/priorities/executive_aggregator.dart';
import 'package:test/test.dart';

Decision _decision({
  required String id,
  required Department department,
  required String title,
  required double impact,
  bool blocked = false,
}) => Decision(
  id: id,
  department: department,
  title: title,
  type: blocked ? DecisionType.blocker : DecisionType.connect,
  priority: DecisionPriority.high,
  score: DecisionScore(impact: impact, urgency: 1.0, evidenceCompleteness: 1.0),
  blocked: blocked,
  reasons: const [DecisionReason('synthetic')],
  evidence: const [FactType.website],
);

DepartmentSummary _summary({
  required Department department,
  double health = 0.5,
  List<Decision> topDecisions = const [],
  List<Decision> blockedDecisions = const [],
  List<String> missingOperationalData = const [],
}) => DepartmentSummary(
  department: department,
  decisionCount: topDecisions.length + blockedDecisions.length,
  blockedCount: blockedDecisions.length,
  observability: health,
  readiness: health,
  health: health,
  topDecisions: topDecisions,
  blockedDecisions: blockedDecisions,
  missingOperationalData: missingOperationalData,
);

void main() {
  test(
    'aggregate() computes company health as the average department health',
    () {
      const aggregator = ExecutiveAggregator();
      final summaries = [
        _summary(department: Department.marketing, health: 0.8),
        _summary(department: Department.finance, health: 0.4),
      ];

      final summary = aggregator.aggregate(summaries);

      expect(summary.companyHealth, closeTo(0.6, 0.0001));
    },
  );

  test('aggregate() merges decisions with the same title raised by different '
      'departments into one entry naming every department it affects', () {
    const aggregator = ExecutiveAggregator();
    final summaries = [
      _summary(
        department: Department.marketing,
        topDecisions: [
          _decision(
            id: 'marketing.ga4',
            department: Department.marketing,
            title: 'Connect GA4',
            impact: 0.9,
          ),
        ],
      ),
      _summary(
        department: Department.sales,
        topDecisions: [
          _decision(
            id: 'sales.ga4',
            department: Department.sales,
            title: 'Connect GA4',
            impact: 0.5,
          ),
        ],
      ),
    ];

    final summary = aggregator.aggregate(summaries);

    expect(summary.topDecisions, hasLength(1));
    expect(summary.topDecisions.single.decision.title, 'Connect GA4');
    expect(summary.topDecisions.single.affects, [
      Department.marketing,
      Department.sales,
    ]);
  });

  test('aggregate() keeps the higher-scoring duplicate as the representative '
      'decision', () {
    const aggregator = ExecutiveAggregator();
    final summaries = [
      _summary(
        department: Department.marketing,
        topDecisions: [
          _decision(
            id: 'marketing.ga4',
            department: Department.marketing,
            title: 'Connect GA4',
            impact: 0.9,
          ),
        ],
      ),
      _summary(
        department: Department.sales,
        topDecisions: [
          _decision(
            id: 'sales.ga4',
            department: Department.sales,
            title: 'Connect GA4',
            impact: 0.5,
          ),
        ],
      ),
    ];

    final summary = aggregator.aggregate(summaries);

    expect(summary.topDecisions.single.decision.id, 'marketing.ga4');
  });

  test('aggregate() ranks and caps company-wide top decisions at 3', () {
    const aggregator = ExecutiveAggregator();
    final summaries = [
      _summary(
        department: Department.marketing,
        topDecisions: [
          for (var i = 0; i < 3; i++)
            _decision(
              id: 'm$i',
              department: Department.marketing,
              title: 'Marketing $i',
              impact: 0.1 * (i + 1),
            ),
        ],
      ),
      _summary(
        department: Department.engineering,
        topDecisions: [
          for (var i = 0; i < 3; i++)
            _decision(
              id: 'e$i',
              department: Department.engineering,
              title: 'Engineering $i',
              impact: 0.2 * (i + 1),
            ),
        ],
      ),
    ];

    final summary = aggregator.aggregate(summaries);

    expect(summary.topDecisions, hasLength(3));
  });

  test('aggregate() never reports "no decisions" when a department has active '
      'work', () {
    const aggregator = ExecutiveAggregator();
    final summaries = [
      _summary(
        department: Department.marketing,
        topDecisions: [
          _decision(
            id: 'm',
            department: Department.marketing,
            title: 'Prepare launch campaign',
            impact: 0.8,
          ),
        ],
      ),
    ];

    final summary = aggregator.aggregate(summaries);

    expect(summary.topDecisions, isNotEmpty);
  });

  test('aggregate() translates raw missing signals into dashboard-level '
      'observability categories, never raw signal names', () {
    const aggregator = ExecutiveAggregator();
    final summaries = [
      _summary(
        department: Department.marketing,
        missingOperationalData: const ['followers', 'reachable'],
      ),
      _summary(
        department: Department.engineering,
        missingOperationalData: const ['ciStatus'],
      ),
    ];

    final summary = aggregator.aggregate(summaries);

    expect(
      summary.observabilityGaps,
      containsAll(['Social Metrics', 'Website Uptime', 'Repository Metrics']),
    );
    expect(summary.observabilityGaps, isNot(contains('followers')));
    expect(summary.observabilityGaps, isNot(contains('reachable')));
  });

  test('aggregate() deduplicates observability categories shared by multiple '
      'raw signals', () {
    const aggregator = ExecutiveAggregator();
    final summaries = [
      _summary(
        department: Department.marketing,
        missingOperationalData: const [
          'analyticsConnected',
          'trafficMetricsAvailable',
          'lastSync',
        ],
      ),
    ];

    final summary = aggregator.aggregate(summaries);

    expect(summary.observabilityGaps, ['Analytics']);
  });

  test('aggregate() is deterministic', () {
    const aggregator = ExecutiveAggregator();
    final summaries = [
      _summary(
        department: Department.marketing,
        topDecisions: [
          _decision(
            id: 'm',
            department: Department.marketing,
            title: 'Prepare launch campaign',
            impact: 0.8,
          ),
        ],
      ),
    ];

    final first = aggregator.aggregate(summaries);
    final second = aggregator.aggregate(summaries);

    expect(first.companyHealth, second.companyHealth);
    expect(
      first.topDecisions.map((d) => d.decision.id).toList(),
      second.topDecisions.map((d) => d.decision.id).toList(),
    );
    expect(first.observabilityGaps, second.observabilityGaps);
  });
}
