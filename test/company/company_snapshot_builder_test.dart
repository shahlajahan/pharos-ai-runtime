import 'package:pharos_ai_runtime/company/company_context.dart';
import 'package:pharos_ai_runtime/company/company_snapshot_builder.dart';
import 'package:test/test.dart';

CompanyContext _emptyContext() => const CompanyContext(
  company: [],
  knowledge: [],
  products: [],
  assets: [],
  services: [],
  websites: [],
  social: [],
  analytics: [],
);

void main() {
  test('CompanySnapshotBuilder produces deterministic output', () {
    const builder = CompanySnapshotBuilder();
    const context = CompanyContext(
      company: ['overview: We build software.'],
      knowledge: ['flutter: Clean architecture.'],
      products: ['petsupo: A pet care marketplace.'],
      assets: [],
      services: [],
      websites: [],
      social: [],
      analytics: [],
    );

    final first = builder.build(context);
    final second = builder.build(context);

    expect(first.company, second.company);
    expect(first.products, second.products);
    expect(first.capabilities, second.capabilities);
    expect(first.assets, second.assets);
    expect(first.websites, second.websites);
    expect(first.analytics, second.analytics);
    expect(first.social, second.social);
    expect(first.services, second.services);
    expect(first.knownData, second.knownData);
    expect(first.missingData, second.missingData);
    expect(first.risks, second.risks);
    expect(first.recommendationsInput, second.recommendationsInput);
  });

  test('duplicate documents are normalized (deduplicated) correctly', () {
    const builder = CompanySnapshotBuilder();
    const context = CompanyContext(
      company: ['overview: We build software.', 'overview: We build software.'],
      knowledge: [],
      products: ['petsupo: A pet care marketplace.'],
      assets: [],
      services: [],
      websites: [],
      social: [],
      analytics: [],
    );

    final snapshot = builder.build(context);

    expect(snapshot.company, ['overview: We build software.']);
  });

  test('missing sections are detected: empty categories and permanently '
      'unconnected categories are both reported as missing', () {
    const builder = CompanySnapshotBuilder();

    final snapshot = builder.build(_emptyContext());

    // Every HQ category is empty, so all 8 must be reported missing...
    expect(
      snapshot.missingData,
      containsAll(<String>[
        'Company',
        'Knowledge',
        'Products',
        'Assets',
        'Websites',
        'Analytics',
        'Social',
        'Services',
      ]),
    );
    // ...plus the categories with no connector at all yet.
    expect(
      snapshot.missingData,
      containsAll(<String>[
        'Revenue',
        'CRM',
        'Campaign Performance',
        'Search Console',
        'Finance',
        'Customer Metrics',
      ]),
    );
    expect(snapshot.knownData, isEmpty);
    // Unknown data must never be fabricated: every known field stays
    // empty when nothing was loaded.
    expect(snapshot.company, isEmpty);
    expect(snapshot.products, isEmpty);
    expect(snapshot.capabilities, isEmpty);
  });

  test('a populated category moves from missingData to knownData', () {
    const builder = CompanySnapshotBuilder();
    const context = CompanyContext(
      company: ['overview: We build software.'],
      knowledge: [],
      products: [],
      assets: [],
      services: [],
      websites: [],
      social: [],
      analytics: [],
    );

    final snapshot = builder.build(context);

    expect(snapshot.knownData, ['Company']);
    expect(snapshot.missingData, isNot(contains('Company')));
  });

  test('risks contains one deterministic entry per missing category', () {
    const builder = CompanySnapshotBuilder();

    final snapshot = builder.build(_emptyContext());

    expect(snapshot.risks, hasLength(snapshot.missingData.length));
    expect(snapshot.risks, everyElement(contains('not connected')));
  });

  test('recommendationsInput combines known products and capabilities '
      '(knowledge)', () {
    const builder = CompanySnapshotBuilder();
    const context = CompanyContext(
      company: [],
      knowledge: ['flutter: Clean architecture.'],
      products: ['petsupo: A pet care marketplace.'],
      assets: [],
      services: [],
      websites: [],
      social: [],
      analytics: [],
    );

    final snapshot = builder.build(context);

    expect(snapshot.recommendationsInput, [
      'petsupo: A pet care marketplace.',
      'flutter: Clean architecture.',
    ]);
  });

  test('CompanySnapshotBuilder performs no LLM calls: build() is '
      'synchronous, returning CompanySnapshot directly rather than a '
      'Future', () {
    const builder = CompanySnapshotBuilder();

    final snapshot = builder.build(_emptyContext());

    expect(snapshot, isNotNull);
  });
}
