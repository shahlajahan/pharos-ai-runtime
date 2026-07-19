import 'package:pharos_ai_runtime/company/company.dart';
import 'package:pharos_ai_runtime/company/departments/finance_department.dart';
import 'package:pharos_ai_runtime/company/governance/budget_area.dart';
import 'package:pharos_ai_runtime/company/governance/company_governance.dart';
import 'package:pharos_ai_runtime/company/governance/ownership.dart';
import 'package:pharos_ai_runtime/company/identity/company_configuration.dart';
import 'package:pharos_ai_runtime/company/identity/company_identity.dart';
import 'package:pharos_ai_runtime/company/identity/company_locale.dart';
import 'package:pharos_ai_runtime/company/identity/company_location.dart';
import 'package:pharos_ai_runtime/company/knowledge/knowledge.dart';
import 'package:pharos_ai_runtime/company/metrics/metrics.dart';
import 'package:pharos_ai_runtime/company/organization/organization.dart';
import 'package:pharos_ai_runtime/company/portfolio/portfolio.dart';
import 'package:pharos_ai_runtime/company/repositories/company_repository.dart';
import 'package:pharos_ai_runtime/company/resources/ai_cost.dart';
import 'package:pharos_ai_runtime/company/resources/api_usage.dart';
import 'package:pharos_ai_runtime/company/resources/budget.dart';
import 'package:pharos_ai_runtime/company/resources/cash_flow.dart';
import 'package:pharos_ai_runtime/company/resources/expenses.dart';
import 'package:pharos_ai_runtime/company/resources/resources.dart';
import 'package:pharos_ai_runtime/company/resources/revenue.dart';
import 'package:test/test.dart';

class _FakeCompanyRepository implements CompanyRepository {
  Company? stored;

  @override
  Future<Company?> load() async => stored;

  @override
  Future<void> save(Company company) async {
    stored = company;
  }
}

void main() {
  test('CompanyRepository contract compiles: exposes load() returning '
      'Company? and save(Company)', () async {
    final repository = _FakeCompanyRepository();
    const company = Company(
      identity: CompanyIdentity(
        id: 'pharos',
        displayName: 'Pharos',
        legalName: 'Pharos Inc.',
      ),
      configuration: CompanyConfiguration(
        locale: CompanyLocale(
          languageCode: 'en',
          countryCode: 'US',
          timeZone: 'UTC',
          currencyCode: 'USD',
        ),
        location: CompanyLocation(country: 'USA', region: 'CA', city: 'SF'),
      ),
      governance: CompanyGovernance(
        ownerships: [
          Ownership(
            businessArea: BudgetArea(),
            department: FinanceDepartment(),
          ),
        ],
      ),
      organization: Organization(departments: []),
      portfolio: Portfolio(products: [], projects: []),
      resources: Resources(
        budget: Budget(),
        revenue: Revenue(),
        cashFlow: CashFlow(),
        expenses: Expenses(),
        aiCost: AiCost(),
        apiUsage: ApiUsage(),
      ),
      knowledge: Knowledge(),
      metrics: Metrics(),
    );

    expect(await repository.load(), isNull);

    await repository.save(company);

    expect(await repository.load(), same(company));
  });
}
