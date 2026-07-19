import 'package:pharos_ai_runtime/company/departments/finance_department.dart';
import 'package:pharos_ai_runtime/company/departments/product_department.dart';
import 'package:pharos_ai_runtime/company/governance/budget_area.dart';
import 'package:pharos_ai_runtime/company/governance/company_governance.dart';
import 'package:pharos_ai_runtime/company/governance/ownership.dart';
import 'package:pharos_ai_runtime/company/governance/portfolio_area.dart';
import 'package:test/test.dart';

void main() {
  test('CompanyGovernance contains Ownerships', () {
    const governance = CompanyGovernance(
      ownerships: [
        Ownership(businessArea: BudgetArea(), department: FinanceDepartment()),
        Ownership(
          businessArea: PortfolioArea(),
          department: ProductDepartment(),
        ),
      ],
    );

    expect(governance.ownerships, hasLength(2));
  });

  test('CompanyGovernance can have no Ownerships', () {
    const governance = CompanyGovernance(ownerships: []);

    expect(governance.ownerships, isEmpty);
  });
}
