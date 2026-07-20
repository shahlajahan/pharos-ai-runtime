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

  test('extract() classifies assets/websites documents as Website (plus '
      'Domain when the name looks like one), visible to Executive and '
      'Marketing', () {
    const extractor = FactExtractor();
    const document = CompanyDocument(
      category: 'assets',
      name: 'petsupo-com',
      path: 'websites/petsupo-com',
      content: 'Marketing website.',
    );

    final facts = extractor.extract([document]);

    expect(facts, hasLength(1));
    expect(facts.single.type, FactType.website);
    expect(facts.single.visibleTo, {
      Department.executive,
      Department.marketing,
    });
  });

  test('extract() classifies assets/domains documents as Domain, visible to '
      'Executive and Marketing', () {
    const extractor = FactExtractor();
    const document = CompanyDocument(
      category: 'assets',
      name: 'petsupo-com',
      path: 'domains/petsupo-com',
      content: 'Primary domain.',
    );

    final fact = extractor.extract([document]).single;

    expect(fact.type, FactType.domain);
    expect(fact.visibleTo, {Department.executive, Department.marketing});
  });

  test('extract() classifies assets/brand documents as BrandAsset, visible '
      'to Executive and Marketing', () {
    const extractor = FactExtractor();
    const document = CompanyDocument(
      category: 'assets',
      name: 'logo-usage',
      path: 'brand/logo-usage',
      content: 'Brand usage guidelines.',
    );

    final fact = extractor.extract([document]).single;

    expect(fact.type, FactType.brandAsset);
    expect(fact.visibleTo, {Department.executive, Department.marketing});
  });

  test('extract() classifies assets/media documents as MediaAsset, visible '
      'to Executive and Marketing', () {
    const extractor = FactExtractor();
    const document = CompanyDocument(
      category: 'assets',
      name: 'hero-video',
      path: 'media/hero-video',
      content: 'Hero video.',
    );

    final fact = extractor.extract([document]).single;

    expect(fact.type, FactType.mediaAsset);
    expect(fact.visibleTo, {Department.executive, Department.marketing});
  });

  test('extract() classifies assets/seo documents as SEOAsset, visible to '
      'Executive and Marketing', () {
    const extractor = FactExtractor();
    const document = CompanyDocument(
      category: 'assets',
      name: 'keyword-strategy',
      path: 'seo/keyword-strategy',
      content: 'SEO keyword strategy.',
    );

    final fact = extractor.extract([document]).single;

    expect(fact.type, FactType.seoAsset);
    expect(fact.visibleTo, {Department.executive, Department.marketing});
  });

  test('extract() classifies assets/ads documents as AdvertisingPlatform, '
      'visible to Executive and Marketing', () {
    const extractor = FactExtractor();
    const document = CompanyDocument(
      category: 'assets',
      name: 'google-ads',
      path: 'ads/google-ads',
      content: 'Google Ads account.',
    );

    final fact = extractor.extract([document]).single;

    expect(fact.type, FactType.advertisingPlatform);
    expect(fact.visibleTo, {Department.executive, Department.marketing});
  });

  test('extract() classifies assets/social documents as SocialAccount, '
      'visible to Executive and Marketing', () {
    const extractor = FactExtractor();
    const document = CompanyDocument(
      category: 'assets',
      name: 'instagram',
      path: 'social/instagram',
      content: 'Instagram account.',
    );

    final fact = extractor.extract([document]).single;

    expect(fact.type, FactType.socialAccount);
    expect(fact.visibleTo, {Department.executive, Department.marketing});
  });

  test('extract() classifies assets/analytics documents as '
      'AnalyticsPlatform, visible to Executive and Marketing', () {
    const extractor = FactExtractor();
    const document = CompanyDocument(
      category: 'assets',
      name: 'ga4',
      path: 'analytics/ga4',
      content: 'Google Analytics 4.',
    );

    final fact = extractor.extract([document]).single;

    expect(fact.type, FactType.analyticsPlatform);
    expect(fact.visibleTo, {Department.executive, Department.marketing});
  });

  test('extract() classifies assets/services documents as Service, visible '
      'to Executive and Engineering', () {
    const extractor = FactExtractor();
    const document = CompanyDocument(
      category: 'assets',
      name: 'firebase',
      path: 'services/firebase',
      content: 'Backend hosting service.',
    );

    final fact = extractor.extract([document]).single;

    expect(fact.type, FactType.service);
    expect(fact.visibleTo, {Department.executive, Department.engineering});
  });

  test('extract() classifies assets/infrastructure documents as '
      'Infrastructure, visible to Executive, Engineering, and Operations', () {
    const extractor = FactExtractor();
    const document = CompanyDocument(
      category: 'assets',
      name: 'hosting',
      path: 'infrastructure/hosting',
      content: 'Cloud hosting setup.',
    );

    final fact = extractor.extract([document]).single;

    expect(fact.type, FactType.infrastructure);
    expect(fact.visibleTo, {
      Department.executive,
      Department.engineering,
      Department.operations,
    });
  });

  test('extract() classifies assets/accounts documents as Account, visible '
      'to Executive and Finance', () {
    const extractor = FactExtractor();
    const document = CompanyDocument(
      category: 'assets',
      name: 'openai',
      path: 'accounts/openai',
      content: 'OpenAI account.',
    );

    final fact = extractor.extract([document]).single;

    expect(fact.type, FactType.account);
    expect(fact.visibleTo, {Department.executive, Department.finance});
  });

  test('extract() classifies assets/crm documents as Account, visible to '
      'Executive and Sales', () {
    const extractor = FactExtractor();
    const document = CompanyDocument(
      category: 'assets',
      name: 'petsupo-partner-crm',
      path: 'crm/petsupo-partner-crm',
      content: 'CRM tool for Petsupo partners.',
    );

    final fact = extractor.extract([document]).single;

    expect(fact.type, FactType.account);
    expect(fact.visibleTo, {Department.executive, Department.sales});
  });

  test('extract() classifies assets/finance documents by name: '
      'PaymentProvider for "payment", Account for "account", Subscription '
      'otherwise', () {
    const extractor = FactExtractor();
    const paymentDocument = CompanyDocument(
      category: 'assets',
      name: 'payment-providers',
      path: 'finance/payment-providers',
      content: 'Payment providers in use.',
    );
    const accountDocument = CompanyDocument(
      category: 'assets',
      name: 'bank-accounts',
      path: 'finance/bank-accounts',
      content: 'Bank accounts.',
    );
    const otherDocument = CompanyDocument(
      category: 'assets',
      name: 'billing-cycle',
      path: 'finance/billing-cycle',
      content: 'Billing cadence.',
    );

    final facts = extractor.extract([
      paymentDocument,
      accountDocument,
      otherDocument,
    ]);

    expect(facts[0].type, FactType.paymentProvider);
    expect(facts[1].type, FactType.account);
    expect(facts[2].type, FactType.subscription);
    for (final fact in facts) {
      expect(fact.visibleTo, {Department.executive, Department.finance});
    }
  });

  test('extract() falls back to the legacy brand/media heuristic for an '
      'unrecognized assets subfolder', () {
    const extractor = FactExtractor();
    const document = CompanyDocument(
      category: 'assets',
      name: 'brand-kit',
      path: 'unrecognized-subfolder/brand-kit',
      content: 'Something unexpected.',
    );

    final fact = extractor.extract([document]).single;

    expect(fact.type, FactType.brandAsset);
  });

  test('extract() preserves the full path in sources for traceability', () {
    const extractor = FactExtractor();
    const document = CompanyDocument(
      category: 'assets',
      name: 'instagram',
      path: 'social/instagram',
      content: 'Instagram account.',
    );

    final fact = extractor.extract([document]).single;

    expect(fact.sources, ['assets/social/instagram']);
  });
}
