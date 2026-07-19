import 'package:pharos_ai_runtime/company/resources/ai_cost.dart';
import 'package:pharos_ai_runtime/company/resources/api_usage.dart';
import 'package:pharos_ai_runtime/company/resources/budget.dart';
import 'package:pharos_ai_runtime/company/resources/cash_flow.dart';
import 'package:pharos_ai_runtime/company/resources/expenses.dart';
import 'package:pharos_ai_runtime/company/resources/revenue.dart';

/// The part of a Company that owns its financial resources. Pure domain
/// structure only — no calculations.
class Resources {
  const Resources({
    required this.budget,
    required this.revenue,
    required this.cashFlow,
    required this.expenses,
    required this.aiCost,
    required this.apiUsage,
  });

  final Budget budget;
  final Revenue revenue;
  final CashFlow cashFlow;
  final Expenses expenses;
  final AiCost aiCost;
  final ApiUsage apiUsage;
}
