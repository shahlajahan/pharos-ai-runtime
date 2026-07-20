import 'package:pharos_ai_runtime/company/department.dart';
import 'package:pharos_ai_runtime/knowledge/company_fact.dart';
import 'package:pharos_ai_runtime/knowledge/fact_type.dart';
import 'package:pharos_ai_runtime/knowledge/knowledge_graph.dart';
import 'package:test/test.dart';

CompanyFact _fact(
  FactType type,
  String name, {
  Set<Department> visibleTo = const {},
}) => CompanyFact(
  id: '${type.name}:$name',
  type: type,
  name: name,
  attributes: const {},
  sources: const [],
  extractionRule: 'test',
  confidence: 1.0,
  visibleTo: visibleTo,
);

void main() {
  test('products() returns only Product facts', () {
    final graph = KnowledgeGraph(
      facts: [
        _fact(FactType.product, 'Petsupo'),
        _fact(FactType.service, 'Firebase'),
      ],
    );

    expect(graph.products().map((f) => f.name), ['Petsupo']);
  });

  test('capabilities() returns only Capability facts', () {
    final graph = KnowledgeGraph(
      facts: [
        _fact(FactType.capability, 'Flutter Architecture'),
        _fact(FactType.product, 'Petsupo'),
      ],
    );

    expect(graph.capabilities().map((f) => f.name), ['Flutter Architecture']);
  });

  test('socialAccounts() returns only SocialAccount facts', () {
    final graph = KnowledgeGraph(
      facts: [_fact(FactType.socialAccount, 'Instagram')],
    );

    expect(graph.socialAccounts().map((f) => f.name), ['Instagram']);
  });

  test('websites() returns only Website facts', () {
    final graph = KnowledgeGraph(
      facts: [_fact(FactType.website, 'petsupo.com')],
    );

    expect(graph.websites().map((f) => f.name), ['petsupo.com']);
  });

  test('competitors() returns only Competitor facts', () {
    final graph = KnowledgeGraph(
      facts: [_fact(FactType.competitor, 'RivalCo')],
    );

    expect(graph.competitors().map((f) => f.name), ['RivalCo']);
  });

  test('technologies() returns only Technology facts', () {
    final graph = KnowledgeGraph(
      facts: [_fact(FactType.technology, 'Flutter')],
    );

    expect(graph.technologies().map((f) => f.name), ['Flutter']);
  });

  test('marketingAssets() returns BrandAsset and MediaAsset facts', () {
    final graph = KnowledgeGraph(
      facts: [
        _fact(FactType.brandAsset, 'Brand Kit'),
        _fact(FactType.mediaAsset, 'Hero Video'),
        _fact(FactType.product, 'Petsupo'),
      ],
    );

    expect(
      graph.marketingAssets().map((f) => f.name),
      containsAll(['Brand Kit', 'Hero Video']),
    );
    expect(graph.marketingAssets(), hasLength(2));
  });

  test('engineeringAssets() returns Repository, Infrastructure, and '
      'Technology facts', () {
    final graph = KnowledgeGraph(
      facts: [
        _fact(FactType.repository, 'pharos-runtime'),
        _fact(FactType.infrastructure, 'Firebase Hosting'),
        _fact(FactType.technology, 'Flutter'),
        _fact(FactType.product, 'Petsupo'),
      ],
    );

    expect(graph.engineeringAssets(), hasLength(3));
  });

  test('factsByType() filters by exact FactType', () {
    final graph = KnowledgeGraph(
      facts: [
        _fact(FactType.product, 'Petsupo'),
        _fact(FactType.product, 'Hubmonix'),
        _fact(FactType.service, 'Firebase'),
      ],
    );

    expect(graph.factsByType(FactType.product), hasLength(2));
  });

  test('factsByDepartment() returns only facts visible to that department', () {
    final graph = KnowledgeGraph(
      facts: [
        _fact(FactType.product, 'Petsupo', visibleTo: {Department.marketing}),
        _fact(FactType.subscription, 'Stripe', visibleTo: {Department.finance}),
      ],
    );

    expect(graph.factsByDepartment(Department.marketing), hasLength(1));
    expect(
      graph.factsByDepartment(Department.marketing).single.name,
      'Petsupo',
    );
  });
}
