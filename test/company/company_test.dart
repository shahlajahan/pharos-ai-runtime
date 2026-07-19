import 'package:pharos_ai_runtime/company/company.dart';
import 'package:pharos_ai_runtime/company/governance/budget_area.dart';
import 'package:pharos_ai_runtime/company/governance/company_governance.dart';
import 'package:pharos_ai_runtime/company/governance/ownership.dart';
import 'package:pharos_ai_runtime/company/departments/finance_department.dart';
import 'package:pharos_ai_runtime/company/identity/company_configuration.dart';
import 'package:pharos_ai_runtime/company/identity/company_identity.dart';
import 'package:pharos_ai_runtime/company/identity/company_locale.dart';
import 'package:pharos_ai_runtime/company/identity/company_location.dart';
import 'package:pharos_ai_runtime/company/knowledge/knowledge.dart';
import 'package:pharos_ai_runtime/company/metrics/metrics.dart';
import 'package:pharos_ai_runtime/company/organization/organization.dart';
import 'package:pharos_ai_runtime/company/portfolio/portfolio.dart';
import 'package:pharos_ai_runtime/company/resources/ai_cost.dart';
import 'package:pharos_ai_runtime/company/resources/api_usage.dart';
import 'package:pharos_ai_runtime/company/resources/budget.dart';
import 'package:pharos_ai_runtime/company/resources/cash_flow.dart';
import 'package:pharos_ai_runtime/company/resources/expenses.dart';
import 'package:pharos_ai_runtime/company/resources/resources.dart';
import 'package:pharos_ai_runtime/company/resources/revenue.dart';
import 'package:test/test.dart';

const _resources = Resources(
  budget: Budget(),
  revenue: Revenue(),
  cashFlow: CashFlow(),
  expenses: Expenses(),
  aiCost: AiCost(),
  apiUsage: ApiUsage(),
);

const _configuration = CompanyConfiguration(
  locale: CompanyLocale(
    languageCode: 'en',
    countryCode: 'US',
    timeZone: 'UTC',
    currencyCode: 'USD',
  ),
  location: CompanyLocation(country: 'USA', region: 'CA', city: 'SF'),
);

Company _company() => const Company(
  identity: CompanyIdentity(
    id: 'pharos',
    displayName: 'Pharos',
    legalName: 'Pharos Inc.',
  ),
  configuration: _configuration,
  governance: CompanyGovernance(
    ownerships: [
      Ownership(businessArea: BudgetArea(), department: FinanceDepartment()),
    ],
  ),
  organization: Organization(departments: []),
  portfolio: Portfolio(products: [], projects: []),
  resources: _resources,
  knowledge: Knowledge(),
  metrics: Metrics(),
);

void main() {
  test('Company can be instantiated', () {
    expect(_company(), isNotNull);
  });

  test('Company exposes Identity', () {
    final company = _company();

    expect(company.identity, isA<CompanyIdentity>());
    expect(company.identity.id, 'pharos');
  });

  test('Company exposes Configuration', () {
    final company = _company();

    expect(company.configuration, isA<CompanyConfiguration>());
    expect(company.configuration.locale, isA<CompanyLocale>());
    expect(company.configuration.location, isA<CompanyLocation>());
  });

  test('Company exposes Governance', () {
    final company = _company();

    expect(company.governance, isA<CompanyGovernance>());
    expect(company.governance.ownerships, hasLength(1));
  });

  test('Company exposes Organization, Portfolio, Resources, Knowledge, and '
      'Metrics', () {
    final company = _company();

    expect(company.organization, isA<Organization>());
    expect(company.portfolio, isA<Portfolio>());
    expect(company.resources, isA<Resources>());
    expect(company.knowledge, isA<Knowledge>());
    expect(company.metrics, isA<Metrics>());
  });
}
