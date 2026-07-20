import 'package:pharos_ai_runtime/company/department.dart';
import 'package:pharos_ai_runtime/knowledge/company_fact.dart';
import 'package:pharos_ai_runtime/knowledge/department_fact_builder.dart';
import 'package:pharos_ai_runtime/knowledge/fact_type.dart';
import 'package:pharos_ai_runtime/knowledge/knowledge_graph.dart';
import 'package:test/test.dart';

CompanyFact _fact(FactType type, String name, Set<Department> visibleTo) =>
    CompanyFact(
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
  test('buildAll() produces one DepartmentFacts per Department', () {
    const builder = DepartmentFactBuilder();
    const graph = KnowledgeGraph(facts: []);

    final all = builder.buildAll(graph);

    expect(all.map((d) => d.department).toList(), Department.values);
  });

  test('Marketing never receives Finance-only facts (department fact '
      'isolation)', () {
    const builder = DepartmentFactBuilder();
    final graph = KnowledgeGraph(
      facts: [
        _fact(FactType.subscription, 'Stripe', {
          Department.executive,
          Department.finance,
        }),
        _fact(FactType.brandAsset, 'Brand Kit', {
          Department.executive,
          Department.marketing,
        }),
      ],
    );

    final marketing = builder.build(Department.marketing, graph);

    expect(marketing.facts.map((f) => f.name), ['Brand Kit']);
    expect(
      marketing.facts.any((f) => f.type == FactType.subscription),
      isFalse,
    );
  });

  test('Finance never receives Marketing-only facts', () {
    const builder = DepartmentFactBuilder();
    final graph = KnowledgeGraph(
      facts: [
        _fact(FactType.subscription, 'Stripe', {
          Department.executive,
          Department.finance,
        }),
        _fact(FactType.brandAsset, 'Brand Kit', {
          Department.executive,
          Department.marketing,
        }),
      ],
    );

    final finance = builder.build(Department.finance, graph);

    expect(finance.facts.map((f) => f.name), ['Stripe']);
  });

  test(
    'build() reports a relevant fact type with no known fact as missing',
    () {
      const builder = DepartmentFactBuilder();
      const graph = KnowledgeGraph(facts: []);

      final marketing = builder.build(Department.marketing, graph);

      expect(marketing.knownTypes, isEmpty);
      expect(marketing.missingTypes, contains(FactType.product));
      expect(marketing.missingTypes, contains(FactType.analyticsPlatform));
    },
  );

  test('build() moves a fact type from missingTypes to knownTypes once a '
      'fact exists', () {
    const builder = DepartmentFactBuilder();
    final graph = KnowledgeGraph(
      facts: [
        _fact(FactType.product, 'Petsupo', {
          Department.executive,
          Department.marketing,
        }),
      ],
    );

    final marketing = builder.build(Department.marketing, graph);

    expect(marketing.knownTypes, contains(FactType.product));
    expect(marketing.missingTypes, isNot(contains(FactType.product)));
  });

  test('build() never reports an irrelevant fact type as missing (for '
      'example Finance never expects Website facts)', () {
    const builder = DepartmentFactBuilder();
    const graph = KnowledgeGraph(facts: []);

    final finance = builder.build(Department.finance, graph);

    expect(finance.missingTypes, isNot(contains(FactType.website)));
  });

  test('build() is deterministic', () {
    const builder = DepartmentFactBuilder();
    final graph = KnowledgeGraph(
      facts: [
        _fact(FactType.product, 'Petsupo', {
          Department.executive,
          Department.marketing,
        }),
      ],
    );

    final first = builder.build(Department.marketing, graph);
    final second = builder.build(Department.marketing, graph);

    expect(first.knownTypes, second.knownTypes);
    expect(first.missingTypes, second.missingTypes);
  });

  test('Marketing receives Website, Domain, BrandAsset, SocialAccount, and '
      'MediaAsset facts when present', () {
    const builder = DepartmentFactBuilder();
    final graph = KnowledgeGraph(
      facts: [
        _fact(FactType.website, 'petsupo.com', {
          Department.executive,
          Department.marketing,
        }),
        _fact(FactType.domain, 'petsupo.com', {
          Department.executive,
          Department.marketing,
        }),
        _fact(FactType.brandAsset, 'Brand Kit', {
          Department.executive,
          Department.marketing,
        }),
        _fact(FactType.socialAccount, 'Instagram', {
          Department.executive,
          Department.marketing,
        }),
        _fact(FactType.mediaAsset, 'Hero Video', {
          Department.executive,
          Department.marketing,
        }),
      ],
    );

    final marketing = builder.build(Department.marketing, graph);

    expect(
      marketing.knownTypes,
      containsAll([
        FactType.website,
        FactType.domain,
        FactType.brandAsset,
        FactType.socialAccount,
        FactType.mediaAsset,
      ]),
    );
    expect(marketing.facts, hasLength(5));
  });

  test('Account facts are visible to both Finance and Sales, but a Finance '
      'account never leaks into Sales and vice versa', () {
    const builder = DepartmentFactBuilder();
    final graph = KnowledgeGraph(
      facts: [
        _fact(FactType.account, 'OpenAI', {
          Department.executive,
          Department.finance,
        }),
        _fact(FactType.account, 'Petsupo Partner CRM', {
          Department.executive,
          Department.sales,
        }),
      ],
    );

    final finance = builder.build(Department.finance, graph);
    final sales = builder.build(Department.sales, graph);

    expect(finance.facts.map((f) => f.name), ['OpenAI']);
    expect(sales.facts.map((f) => f.name), ['Petsupo Partner CRM']);
  });

  test('Marketing receives AdvertisingPlatform facts when present', () {
    const builder = DepartmentFactBuilder();
    final graph = KnowledgeGraph(
      facts: [
        _fact(FactType.advertisingPlatform, 'Google Ads', {
          Department.executive,
          Department.marketing,
        }),
      ],
    );

    final marketing = builder.build(Department.marketing, graph);

    expect(marketing.knownTypes, contains(FactType.advertisingPlatform));
  });

  test('Operations and Engineering both receive Infrastructure facts', () {
    const builder = DepartmentFactBuilder();
    final graph = KnowledgeGraph(
      facts: [
        _fact(FactType.infrastructure, 'Cloud Hosting', {
          Department.executive,
          Department.engineering,
          Department.operations,
        }),
      ],
    );

    final operations = builder.build(Department.operations, graph);
    final engineering = builder.build(Department.engineering, graph);

    expect(operations.knownTypes, contains(FactType.infrastructure));
    expect(engineering.knownTypes, contains(FactType.infrastructure));
  });
}
