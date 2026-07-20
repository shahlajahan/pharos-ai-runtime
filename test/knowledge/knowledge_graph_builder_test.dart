import 'package:pharos_ai_runtime/company/department.dart';
import 'package:pharos_ai_runtime/knowledge/company_fact.dart';
import 'package:pharos_ai_runtime/knowledge/fact_type.dart';
import 'package:pharos_ai_runtime/knowledge/knowledge_graph_builder.dart';
import 'package:test/test.dart';

CompanyFact _fact({
  required String id,
  List<String> sources = const [],
  double confidence = 1.0,
  Set<Department> visibleTo = const {},
}) => CompanyFact(
  id: id,
  type: FactType.product,
  name: 'Petsupo',
  attributes: const {},
  sources: sources,
  extractionRule: 'product-from-category',
  confidence: confidence,
  visibleTo: visibleTo,
);

void main() {
  test('build() keeps one fact per unique id', () {
    const builder = KnowledgeGraphBuilder();

    final graph = builder.build([
      _fact(id: 'product:petsupo', sources: ['products/petsupo']),
      _fact(id: 'product:hubmonix', sources: ['products/hubmonix']),
    ]);

    expect(graph.facts, hasLength(2));
  });

  test('build() merges duplicate facts sharing the same id, combining '
      'sources', () {
    const builder = KnowledgeGraphBuilder();

    final graph = builder.build([
      _fact(id: 'product:petsupo', sources: ['products/petsupo']),
      _fact(
        id: 'product:petsupo',
        sources: ['knowledge/company/products/petsupo'],
      ),
    ]);

    expect(graph.facts, hasLength(1));
    expect(graph.facts.single.sources, [
      'products/petsupo',
      'knowledge/company/products/petsupo',
    ]);
  });

  test('build() merges visibility across duplicates', () {
    const builder = KnowledgeGraphBuilder();

    final graph = builder.build([
      _fact(id: 'product:petsupo', visibleTo: {Department.marketing}),
      _fact(id: 'product:petsupo', visibleTo: {Department.engineering}),
    ]);

    expect(graph.facts.single.visibleTo, {
      Department.marketing,
      Department.engineering,
    });
  });

  test('build() keeps the higher confidence when merging duplicates', () {
    const builder = KnowledgeGraphBuilder();

    final graph = builder.build([
      _fact(id: 'product:petsupo', confidence: 0.8),
      _fact(id: 'product:petsupo', confidence: 1.0),
    ]);

    expect(graph.facts.single.confidence, 1.0);
  });

  test('build() is deterministic', () {
    const builder = KnowledgeGraphBuilder();
    final facts = [
      _fact(id: 'product:petsupo', sources: ['products/petsupo']),
    ];

    final first = builder.build(facts);
    final second = builder.build(facts);

    expect(first.facts.length, second.facts.length);
    expect(first.facts.single.sources, second.facts.single.sources);
  });
}
