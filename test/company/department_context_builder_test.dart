import 'package:pharos_ai_runtime/company/company_context.dart';
import 'package:pharos_ai_runtime/company/department.dart';
import 'package:pharos_ai_runtime/company/department_context_builder.dart';
import 'package:test/test.dart';

CompanyContext _context() => const CompanyContext(
  company: ['identity: Pharos builds AI-native software products.'],
  knowledge: [
    'seo-notes: SEO and social media campaign playbook for marketing.',
    'architecture-notes: Backend API and infrastructure architecture for '
        'engineering.',
    'billing-notes: Finance billing and subscription payment provider '
        'notes.',
    'pipeline-notes: Sales CRM lead pipeline and partnership notes.',
    'workflow-notes: Operations workflow automation notes.',
  ],
  products: ['petsupo: A pet care marketplace.'],
  assets: ['brand-kit: Logo and brand guidelines.'],
  services: ['firebase: Backend hosting service.'],
  websites: ['petsupo.com: Marketing website.'],
  social: ['instagram: @petsupo'],
  analytics: ['ga4: Website analytics.'],
);

void main() {
  test('buildAll() produces one DepartmentContext per Department', () {
    const builder = DepartmentContextBuilder();

    final contexts = builder.buildAll(_context());

    expect(contexts.map((c) => c.department).toList(), Department.values);
  });

  test('every department receives Company, unfiltered', () {
    const builder = DepartmentContextBuilder();

    for (final department in Department.values) {
      final context = builder.build(department, _context());
      expect(context.company, _context().company);
    }
  });

  test('Marketing context extraction: receives products, assets, websites, '
      'social, analytics, and marketing-relevant knowledge, but not '
      'services', () {
    const builder = DepartmentContextBuilder();

    final marketing = builder.build(Department.marketing, _context());

    expect(marketing.products, isNotEmpty);
    expect(marketing.assets, isNotEmpty);
    expect(marketing.websites, isNotEmpty);
    expect(marketing.social, isNotEmpty);
    expect(marketing.analytics, isNotEmpty);
    expect(marketing.services, isEmpty);
    expect(
      marketing.knowledge,
      contains(contains('SEO and social media campaign playbook')),
    );
  });

  test('Engineering context extraction: receives products and services, but '
      'not assets, websites, social, or analytics', () {
    const builder = DepartmentContextBuilder();

    final engineering = builder.build(Department.engineering, _context());

    expect(engineering.products, isNotEmpty);
    expect(engineering.services, isNotEmpty);
    expect(engineering.assets, isEmpty);
    expect(engineering.websites, isEmpty);
    expect(engineering.social, isEmpty);
    expect(engineering.analytics, isEmpty);
    expect(
      engineering.knowledge,
      contains(contains('Backend API and infrastructure architecture')),
    );
  });

  test('Department isolation: Marketing never receives Finance-only '
      'knowledge, and Finance never receives Marketing-only knowledge or '
      'unrelated categories', () {
    const builder = DepartmentContextBuilder();

    final marketing = builder.build(Department.marketing, _context());
    final finance = builder.build(Department.finance, _context());

    expect(
      marketing.knowledge.any((entry) => entry.contains('billing')),
      isFalse,
    );
    expect(finance.knowledge.any((entry) => entry.contains('SEO')), isFalse);
    expect(finance.products, isEmpty);
    expect(finance.assets, isEmpty);
    expect(finance.websites, isEmpty);
    expect(finance.social, isEmpty);
  });

  test('Executive receives every category unfiltered, including all '
      'Knowledge regardless of department vocabulary', () {
    const builder = DepartmentContextBuilder();

    final executive = builder.build(Department.executive, _context());

    expect(executive.knowledge, _context().knowledge);
    expect(executive.products, _context().products);
    expect(executive.assets, _context().assets);
    expect(executive.services, _context().services);
    expect(executive.websites, _context().websites);
    expect(executive.social, _context().social);
    expect(executive.analytics, _context().analytics);
  });

  test('build() is deterministic', () {
    const builder = DepartmentContextBuilder();

    final first = builder.build(Department.marketing, _context());
    final second = builder.build(Department.marketing, _context());

    expect(first.knowledge, second.knowledge);
    expect(first.relevantCategories, second.relevantCategories);
  });
}
