import 'package:pharos_ai_runtime/company/departments/department.dart';
import 'package:pharos_ai_runtime/company/products/product.dart';
import 'package:pharos_ai_runtime/company/projects/project.dart';
import 'package:pharos_ai_runtime/company/resources/ai_cost.dart';
import 'package:pharos_ai_runtime/company/resources/api_usage.dart';
import 'package:pharos_ai_runtime/company/resources/budget.dart';
import 'package:pharos_ai_runtime/company/resources/cash_flow.dart';
import 'package:pharos_ai_runtime/company/resources/expenses.dart';
import 'package:pharos_ai_runtime/company/resources/revenue.dart';

/// The business root of Pharos HQ: the entire organization, expressed as
/// a pure domain model. Company is not a Workflow, not Runtime, and not
/// HQ — it owns no execution, no business logic, and no persistence. It
/// only exposes the organization's structure through strongly typed
/// references.
class Company {
  const Company({
    required this.departments,
    required this.products,
    required this.projects,
    required this.budget,
    required this.revenue,
    required this.cashFlow,
    required this.expenses,
    required this.aiCost,
    required this.apiUsage,
  });

  final List<Department> departments;
  final List<Product> products;
  final List<Project> projects;
  final Budget budget;
  final Revenue revenue;
  final CashFlow cashFlow;
  final Expenses expenses;
  final AiCost aiCost;
  final ApiUsage apiUsage;
}
