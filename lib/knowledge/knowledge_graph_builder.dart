import 'package:pharos_ai_runtime/knowledge/company_fact.dart';
import 'package:pharos_ai_runtime/knowledge/knowledge_graph.dart';

/// Builds one KnowledgeGraph from every extracted CompanyFact, merging
/// duplicates that share the same id (for example the same product
/// mentioned by both `products/petsupo` and
/// `knowledge/company/products/petsupo`) into a single fact with
/// combined sources and visibility.
class KnowledgeGraphBuilder {
  const KnowledgeGraphBuilder();

  KnowledgeGraph build(List<CompanyFact> facts) {
    final byId = <String, CompanyFact>{};

    for (final fact in facts) {
      final existing = byId[fact.id];
      byId[fact.id] = existing == null ? fact : _merge(existing, fact);
    }

    return KnowledgeGraph(facts: byId.values.toList());
  }

  CompanyFact _merge(CompanyFact first, CompanyFact second) {
    return CompanyFact(
      id: first.id,
      type: first.type,
      name: first.name,
      attributes: {...second.attributes, ...first.attributes},
      sources: _dedupe([...first.sources, ...second.sources]),
      extractionRule: first.extractionRule,
      confidence: first.confidence >= second.confidence
          ? first.confidence
          : second.confidence,
      visibleTo: {...first.visibleTo, ...second.visibleTo},
    );
  }

  List<String> _dedupe(List<String> entries) {
    final seen = <String>{};
    return [
      for (final entry in entries)
        if (seen.add(entry)) entry,
    ];
  }
}
