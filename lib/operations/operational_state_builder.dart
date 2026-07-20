import 'package:pharos_ai_runtime/knowledge/company_fact.dart';
import 'package:pharos_ai_runtime/knowledge/fact_type.dart';
import 'package:pharos_ai_runtime/knowledge/knowledge_graph.dart';
import 'package:pharos_ai_runtime/operations/operational_state.dart';

/// Builds one OperationalState per CompanyFact. Only deterministic
/// rules: a readiness signal is [SignalState.yes] or [SignalState.no]
/// only when something else in the Knowledge Graph (or the fact that
/// this Runtime has no live connector at all yet) settles it with
/// certainty; otherwise it stays [SignalState.unknown]. No AI, no
/// filesystem, no HTTP, no connectors — existence of a fact is never
/// treated as evidence of readiness.
class OperationalStateBuilder {
  const OperationalStateBuilder();

  List<OperationalState> buildAll(KnowledgeGraph graph) => [
    for (final fact in graph.facts) build(fact, graph),
  ];

  OperationalState build(CompanyFact fact, KnowledgeGraph graph) {
    return OperationalState(
      factId: fact.id,
      factType: fact.type,
      name: fact.name,
      signals: _signalsFor(fact, graph),
    );
  }

  Map<String, SignalState> _signalsFor(CompanyFact fact, KnowledgeGraph graph) {
    switch (fact.type) {
      case FactType.website:
        return {
          'exists': SignalState.yes,
          'reachable': SignalState.unknown,
          'analyticsConnected': graph.analyticsPlatforms().isEmpty
              ? SignalState.no
              : SignalState.yes,
          'trafficMetricsAvailable': SignalState.no,
          'lastDeploy': SignalState.unknown,
        };
      case FactType.socialAccount:
        return {
          'exists': SignalState.yes,
          'followers': SignalState.unknown,
          'engagement': SignalState.unknown,
          'postingFrequency': SignalState.unknown,
          'insightsConnected': SignalState.no,
        };
      case FactType.analyticsPlatform:
        return {
          'exists': SignalState.yes,
          'configured': SignalState.yes,
          'liveMetricsAvailable': SignalState.no,
          'lastSync': SignalState.unknown,
        };
      case FactType.repository:
        return {
          'exists': SignalState.yes,
          'ciStatus': SignalState.unknown,
          'deploymentStatus': SignalState.unknown,
          'documentationCoverage': SignalState.unknown,
        };
      case FactType.paymentProvider:
      case FactType.subscription:
        return {
          'exists': SignalState.yes,
          'billingStatus': SignalState.unknown,
          'revenueAvailable': SignalState.no,
        };
      default:
        // Existence-only entities (Product, BrandAsset, MediaAsset,
        // ...): no additional operational readiness is expected — their
        // existence alone is sufficient evidence.
        return {'exists': SignalState.yes};
    }
  }
}
