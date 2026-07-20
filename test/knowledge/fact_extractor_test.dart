import 'package:pharos_ai_runtime/company/company_document.dart';
import 'package:pharos_ai_runtime/company/department.dart';
import 'package:pharos_ai_runtime/knowledge/fact_extractor.dart';
import 'package:pharos_ai_runtime/knowledge/fact_type.dart';
import 'package:test/test.dart';

void main() {
  test('extract() produces a Product fact from a products document, visible '
      'to Executive, Marketing, Engineering, and Sales', () {
    const extractor = FactExtractor();
    const document = CompanyDocument(
      category: 'products',
      name: 'petsupo',
      content: '# Petsupo\n\nA pet care marketplace.',
    );

    final facts = extractor.extract([document]);

    expect(facts, hasLength(1));
    final fact = facts.single;
    expect(fact.id, 'product:petsupo');
    expect(fact.type, FactType.product);
    expect(fact.name, 'petsupo');
    expect(fact.visibleTo, {
      Department.executive,
      Department.marketing,
      Department.engineering,
      Department.sales,
    });
  });

  test('extract() never carries raw document content into a fact', () {
    const extractor = FactExtractor();
    const document = CompanyDocument(
      category: 'products',
      name: 'petsupo',
      content: 'This raw markdown prose must never reach a fact.',
    );

    final fact = extractor.extract([document]).single;

    expect(fact.attributes, isEmpty);
    expect(fact.name, isNot(contains('raw markdown prose')));
    expect(fact.sources.join(), isNot(contains('raw markdown prose')));
  });

  test('extract() records evidence: source document, extraction rule, and '
      'confidence for every fact', () {
    const extractor = FactExtractor();
    const document = CompanyDocument(
      category: 'services',
      name: 'firebase',
      content: 'Backend hosting service.',
    );

    final fact = extractor.extract([document]).single;

    expect(fact.sources, ['services/firebase']);
    expect(fact.extractionRule, isNotEmpty);
    expect(fact.confidence, 1.0);
  });

  test('extract() classifies an assets document containing "brand" as a '
      'BrandAsset, and other assets as MediaAsset', () {
    const extractor = FactExtractor();
    const brandDocument = CompanyDocument(
      category: 'assets',
      name: 'brand-kit',
      content: 'Logo and brand guidelines.',
    );
    const mediaDocument = CompanyDocument(
      category: 'assets',
      name: 'hero-video',
      content: 'Hero video.',
    );

    final facts = extractor.extract([brandDocument, mediaDocument]);

    expect(facts[0].type, FactType.brandAsset);
    expect(facts[1].type, FactType.mediaAsset);
  });

  test('extract() emits both a Website and a Domain fact for a website '
      'document whose name looks like a domain', () {
    const extractor = FactExtractor();
    const document = CompanyDocument(
      category: 'websites',
      name: 'petsupo.com',
      content: 'Marketing website.',
    );

    final facts = extractor.extract([document]);

    expect(
      facts.map((f) => f.type),
      containsAll([FactType.website, FactType.domain]),
    );
  });

  test('extract() does not emit a Domain fact for a website document whose '
      'name is not a domain', () {
    const extractor = FactExtractor();
    const document = CompanyDocument(
      category: 'websites',
      name: 'main-site',
      content: 'Marketing website.',
    );

    final facts = extractor.extract([document]);

    expect(facts, hasLength(1));
    expect(facts.single.type, FactType.website);
  });

  test('extract() assigns Knowledge document visibility by matching '
      'department vocabulary, always including Executive', () {
    const extractor = FactExtractor();
    const document = CompanyDocument(
      category: 'knowledge',
      name: 'seo-notes',
      content: 'SEO and social media campaign playbook for marketing.',
    );

    final fact = extractor.extract([document]).single;

    expect(fact.type, FactType.capability);
    expect(fact.visibleTo, contains(Department.executive));
    expect(fact.visibleTo, contains(Department.marketing));
    expect(fact.visibleTo, isNot(contains(Department.finance)));
  });

  test('extract() ignores documents from an unrecognized category rather '
      'than guessing a fact type', () {
    const extractor = FactExtractor();
    const document = CompanyDocument(
      category: 'random',
      name: 'mystery',
      content: 'Unrecognized content.',
    );

    final facts = extractor.extract([document]);

    expect(facts, isEmpty);
  });

  test('extract() is deterministic', () {
    const extractor = FactExtractor();
    const document = CompanyDocument(
      category: 'products',
      name: 'petsupo',
      content: 'A pet care marketplace.',
    );

    final first = extractor.extract([document]);
    final second = extractor.extract([document]);

    expect(first.single.id, second.single.id);
    expect(first.single.visibleTo, second.single.visibleTo);
  });
}
