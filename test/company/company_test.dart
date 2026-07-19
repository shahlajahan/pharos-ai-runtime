import 'package:pharos_ai_runtime/company/company.dart';
import 'package:pharos_ai_runtime/company/departments/ceo_office.dart';
import 'package:pharos_ai_runtime/company/departments/department.dart';
import 'package:pharos_ai_runtime/company/departments/finance_department.dart';
import 'package:pharos_ai_runtime/company/products/product.dart';
import 'package:pharos_ai_runtime/company/projects/project.dart';
import 'package:pharos_ai_runtime/company/resources/ai_cost.dart';
import 'package:pharos_ai_runtime/company/resources/api_usage.dart';
import 'package:pharos_ai_runtime/company/resources/budget.dart';
import 'package:pharos_ai_runtime/company/resources/cash_flow.dart';
import 'package:pharos_ai_runtime/company/resources/expenses.dart';
import 'package:pharos_ai_runtime/company/resources/revenue.dart';
import 'package:test/test.dart';

void main() {
  test('Company can be instantiated', () {
    const company = Company(
      departments: [CeoOffice(), FinanceDepartment()],
      products: [Product(id: 'p1', name: 'Pharos Runtime')],
      projects: [Project(id: 'j1', name: 'Company Domain Foundation')],
      budget: Budget(),
      revenue: Revenue(),
      cashFlow: CashFlow(),
      expenses: Expenses(),
      aiCost: AiCost(),
      apiUsage: ApiUsage(),
    );

    expect(company, isNotNull);
  });

  test('Company exposes strongly typed business objects', () {
    const company = Company(
      departments: [CeoOffice()],
      products: [Product(id: 'p1', name: 'Pharos Runtime')],
      projects: [Project(id: 'j1', name: 'Company Domain Foundation')],
      budget: Budget(),
      revenue: Revenue(),
      cashFlow: CashFlow(),
      expenses: Expenses(),
      aiCost: AiCost(),
      apiUsage: ApiUsage(),
    );

    expect(company.departments, isA<List<Department>>());
    expect(company.products, isA<List<Product>>());
    expect(company.projects, isA<List<Project>>());
    expect(company.budget, isA<Budget>());
    expect(company.revenue, isA<Revenue>());
    expect(company.cashFlow, isA<CashFlow>());
    expect(company.expenses, isA<Expenses>());
    expect(company.aiCost, isA<AiCost>());
    expect(company.apiUsage, isA<ApiUsage>());
  });

  test('Company can hold an empty organization', () {
    const company = Company(
      departments: [],
      products: [],
      projects: [],
      budget: Budget(),
      revenue: Revenue(),
      cashFlow: CashFlow(),
      expenses: Expenses(),
      aiCost: AiCost(),
      apiUsage: ApiUsage(),
    );

    expect(company.departments, isEmpty);
    expect(company.products, isEmpty);
    expect(company.projects, isEmpty);
  });
}
