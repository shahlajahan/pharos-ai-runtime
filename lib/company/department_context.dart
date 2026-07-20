import 'package:pharos_ai_runtime/company/department.dart';

/// The subset of CompanyContext relevant to one Department. Deterministic
/// and immutable: DepartmentContextBuilder alone decides what each
/// department can see. DepartmentContext never calls the LLM and never
/// reasons about what it holds — it only carries already-filtered facts.
class DepartmentContext {
  const DepartmentContext({
    required this.department,
    required this.relevantCategories,
    required this.company,
    required this.knowledge,
    required this.products,
    required this.assets,
    required this.services,
    required this.websites,
    required this.social,
    required this.analytics,
  });

  final Department department;

  /// The CompanyContext categories this department reasons over (for
  /// example {'Company', 'Products', 'Knowledge'} for Sales). A category
  /// outside this set is never populated below, and is therefore never
  /// reported as missing either — a department is only "missing" data it
  /// could actually use.
  final Set<String> relevantCategories;

  final List<String> company;
  final List<String> knowledge;
  final List<String> products;
  final List<String> assets;
  final List<String> services;
  final List<String> websites;
  final List<String> social;
  final List<String> analytics;
}
