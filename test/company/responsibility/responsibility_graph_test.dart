import 'package:pharos_ai_runtime/company/capabilities/engineering_capability.dart';
import 'package:pharos_ai_runtime/company/capabilities/finance_capability.dart';
import 'package:pharos_ai_runtime/company/capabilities/marketing_capability.dart';
import 'package:pharos_ai_runtime/company/departments/engineering_department.dart';
import 'package:pharos_ai_runtime/company/departments/finance_department.dart';
import 'package:pharos_ai_runtime/company/departments/marketing_department.dart';
import 'package:pharos_ai_runtime/company/governance/budget_area.dart';
import 'package:pharos_ai_runtime/company/governance/portfolio_area.dart';
import 'package:pharos_ai_runtime/company/responsibility/responsibility.dart';
import 'package:pharos_ai_runtime/company/responsibility/responsibility_graph.dart';
import 'package:pharos_ai_runtime/company/work/work_type.dart';
import 'package:test/test.dart';

void main() {
  test('ResponsibilityGraph contains Responsibilities', () {
    const graph = ResponsibilityGraph(
      responsibilities: [
        Responsibility(
          department: EngineeringDepartment(),
          capability: EngineeringCapability(),
          businessArea: PortfolioArea(),
          workType: WorkType.engineering,
        ),
        Responsibility(
          department: MarketingDepartment(),
          capability: MarketingCapability(),
          businessArea: PortfolioArea(),
          workType: WorkType.marketing,
        ),
        Responsibility(
          department: FinanceDepartment(),
          capability: FinanceCapability(),
          businessArea: BudgetArea(),
          workType: WorkType.finance,
        ),
      ],
    );

    expect(graph.responsibilities, hasLength(3));
  });

  test('ResponsibilityGraph can be empty', () {
    const graph = ResponsibilityGraph(responsibilities: []);

    expect(graph.responsibilities, isEmpty);
  });
}
