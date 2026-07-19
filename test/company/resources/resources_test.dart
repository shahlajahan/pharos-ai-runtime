import 'package:pharos_ai_runtime/company/resources/ai_cost.dart';
import 'package:pharos_ai_runtime/company/resources/api_usage.dart';
import 'package:pharos_ai_runtime/company/resources/budget.dart';
import 'package:pharos_ai_runtime/company/resources/cash_flow.dart';
import 'package:pharos_ai_runtime/company/resources/expenses.dart';
import 'package:pharos_ai_runtime/company/resources/resources.dart';
import 'package:pharos_ai_runtime/company/resources/revenue.dart';
import 'package:test/test.dart';

void main() {
  test('Resources exposes Budget, Revenue, CashFlow, Expenses, AiCost, and '
      'ApiUsage', () {
    const resources = Resources(
      budget: Budget(),
      revenue: Revenue(),
      cashFlow: CashFlow(),
      expenses: Expenses(),
      aiCost: AiCost(),
      apiUsage: ApiUsage(),
    );

    expect(resources.budget, isA<Budget>());
    expect(resources.revenue, isA<Revenue>());
    expect(resources.cashFlow, isA<CashFlow>());
    expect(resources.expenses, isA<Expenses>());
    expect(resources.aiCost, isA<AiCost>());
    expect(resources.apiUsage, isA<ApiUsage>());
  });
}
