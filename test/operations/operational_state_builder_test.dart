import 'package:pharos_ai_runtime/knowledge/company_fact.dart';
import 'package:pharos_ai_runtime/knowledge/fact_type.dart';
import 'package:pharos_ai_runtime/knowledge/knowledge_graph.dart';
import 'package:pharos_ai_runtime/operations/operational_state.dart';
import 'package:pharos_ai_runtime/operations/operational_state_builder.dart';
import 'package:test/test.dart';

CompanyFact _fact(FactType type, String name) => CompanyFact(
  id: '${type.name}:$name',
  type: type,
  name: name,
  attributes: const {},
  sources: const [],
  extractionRule: 'test',
  confidence: 1.0,
  visibleTo: const {},
);

void main() {
  test('build() always includes "exists" as SignalState.yes', () {
    const builder = OperationalStateBuilder();
    const graph = KnowledgeGraph(facts: []);

    final state = builder.build(_fact(FactType.product, 'Petsupo'), graph);

    expect(state.signals['exists'], SignalState.yes);
    expect(state.factId, 'product:Petsupo');
    expect(state.factType, FactType.product);
    expect(state.name, 'Petsupo');
  });

  test('build() treats existence-only types (for example Product) as fully '
      'known: only "exists" is tracked', () {
    const builder = OperationalStateBuilder();
    const graph = KnowledgeGraph(facts: []);

    final state = builder.build(_fact(FactType.brandAsset, 'Brand Kit'), graph);

    expect(state.signals, {'exists': SignalState.yes});
  });

  test('build() for a Website: reachable and lastDeploy stay unknown, '
      'trafficMetricsAvailable is always No', () {
    const builder = OperationalStateBuilder();
    const graph = KnowledgeGraph(facts: []);

    final state = builder.build(_fact(FactType.website, 'petsupo.com'), graph);

    expect(state.signals['reachable'], SignalState.unknown);
    expect(state.signals['lastDeploy'], SignalState.unknown);
    expect(state.signals['trafficMetricsAvailable'], SignalState.no);
  });

  test('build() for a Website: analyticsConnected is No when the graph has '
      'no AnalyticsPlatform fact', () {
    const builder = OperationalStateBuilder();
    const graph = KnowledgeGraph(facts: []);

    final state = builder.build(_fact(FactType.website, 'petsupo.com'), graph);

    expect(state.signals['analyticsConnected'], SignalState.no);
  });

  test('build() for a Website: analyticsConnected is Yes when the graph has '
      'an AnalyticsPlatform fact', () {
    const builder = OperationalStateBuilder();
    final graph = KnowledgeGraph(
      facts: [_fact(FactType.analyticsPlatform, 'GA4')],
    );

    final state = builder.build(_fact(FactType.website, 'petsupo.com'), graph);

    expect(state.signals['analyticsConnected'], SignalState.yes);
  });

  test('build() for a SocialAccount: followers, engagement, and '
      'postingFrequency stay unknown; insightsConnected is always No', () {
    const builder = OperationalStateBuilder();
    const graph = KnowledgeGraph(facts: []);

    final state = builder.build(
      _fact(FactType.socialAccount, 'Instagram'),
      graph,
    );

    expect(state.signals['followers'], SignalState.unknown);
    expect(state.signals['engagement'], SignalState.unknown);
    expect(state.signals['postingFrequency'], SignalState.unknown);
    expect(state.signals['insightsConnected'], SignalState.no);
  });

  test('build() for an AnalyticsPlatform: configured is always Yes, '
      'liveMetricsAvailable is always No, lastSync stays unknown', () {
    const builder = OperationalStateBuilder();
    const graph = KnowledgeGraph(facts: []);

    final state = builder.build(
      _fact(FactType.analyticsPlatform, 'GA4'),
      graph,
    );

    expect(state.signals['configured'], SignalState.yes);
    expect(state.signals['liveMetricsAvailable'], SignalState.no);
    expect(state.signals['lastSync'], SignalState.unknown);
  });

  test('build() for a Repository: ciStatus, deploymentStatus, and '
      'documentationCoverage stay unknown', () {
    const builder = OperationalStateBuilder();
    const graph = KnowledgeGraph(facts: []);

    final state = builder.build(
      _fact(FactType.repository, 'pharos-runtime'),
      graph,
    );

    expect(state.signals['ciStatus'], SignalState.unknown);
    expect(state.signals['deploymentStatus'], SignalState.unknown);
    expect(state.signals['documentationCoverage'], SignalState.unknown);
  });

  test('build() for a PaymentProvider or Subscription: billingStatus stays '
      'unknown, revenueAvailable is always No', () {
    const builder = OperationalStateBuilder();
    const graph = KnowledgeGraph(facts: []);

    final payment = builder.build(
      _fact(FactType.paymentProvider, 'Stripe'),
      graph,
    );
    final subscription = builder.build(
      _fact(FactType.subscription, 'OpenAI'),
      graph,
    );

    for (final state in [payment, subscription]) {
      expect(state.signals['billingStatus'], SignalState.unknown);
      expect(state.signals['revenueAvailable'], SignalState.no);
    }
  });

  test('buildAll() builds one OperationalState per fact in the graph', () {
    const builder = OperationalStateBuilder();
    final graph = KnowledgeGraph(
      facts: [
        _fact(FactType.product, 'Petsupo'),
        _fact(FactType.website, 'petsupo.com'),
      ],
    );

    final states = builder.buildAll(graph);

    expect(states, hasLength(2));
  });

  test('build() is deterministic', () {
    const builder = OperationalStateBuilder();
    const graph = KnowledgeGraph(facts: []);
    final fact = _fact(FactType.website, 'petsupo.com');

    final first = builder.build(fact, graph);
    final second = builder.build(fact, graph);

    expect(first.signals, second.signals);
  });
}
