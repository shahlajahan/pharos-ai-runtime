import 'package:pharos_ai_runtime/registry/company_product.dart';

/// The Pharos company's own product portfolio, used for internal
/// reporting (starting with the daily report). Hardcoded for now.
class CompanyRegistry {
  const CompanyRegistry();

  static const List<CompanyProduct> _products = [
    CompanyProduct(
      name: 'Petsupo',
      enabled: true,
      description:
          'A marketplace connecting pet owners with local pet care and '
          'grooming services.',
      targetAudience:
          'Pet owners looking for trustworthy local pet care providers.',
      valueProposition:
          'Book vetted pet care services in minutes, all in one place.',
    ),
    CompanyProduct(
      name: 'DevAudit',
      enabled: true,
      description:
          'An automated code quality and security auditing tool for '
          'software teams.',
      targetAudience:
          'Engineering teams and CTOs who need continuous code quality '
          'assurance.',
      valueProposition:
          'Catch code quality and security issues before they reach '
          'production.',
    ),
    CompanyProduct(
      name: 'HubMonix',
      enabled: true,
      description:
          'A unified monitoring and observability platform for '
          'distributed systems.',
      targetAudience:
          'DevOps and platform engineering teams running production '
          'infrastructure.',
      valueProposition:
          'See everything happening across your infrastructure from one '
          'dashboard.',
    ),
    CompanyProduct(
      name: 'devclean',
      enabled: true,
      description:
          'A tool that automatically cleans up unused dependencies, dead '
          'code, and build artifacts.',
      targetAudience:
          'Developers and teams maintaining large, long-lived codebases.',
      valueProposition:
          'Keep your codebase lean and fast without manual cleanup work.',
    ),
    CompanyProduct(
      name: 'leadforge',
      enabled: true,
      description:
          'A lead generation and enrichment platform for B2B sales teams.',
      targetAudience:
          'Sales and growth teams looking to fill their pipeline with '
          'qualified leads.',
      valueProposition:
          'Turn raw contact data into sales-ready, enriched leads '
          'automatically.',
    ),
  ];

  /// Every product in the portfolio, enabled or not.
  List<CompanyProduct> get products => _products;

  /// Only the enabled products, in the portfolio's order.
  List<CompanyProduct> enabledProducts() =>
      _products.where((product) => product.enabled).toList();
}
