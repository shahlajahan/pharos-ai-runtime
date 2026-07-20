import 'package:pharos_ai_runtime/company/company_context.dart';
import 'package:pharos_ai_runtime/company/department.dart';
import 'package:pharos_ai_runtime/company/department_context.dart';

/// Builds one DepartmentContext per Department from a single CompanyContext.
/// Only extraction: no prompting, no reasoning, no recommendations. Every
/// department sees "Company" and a keyword-filtered slice of "Knowledge";
/// the remaining categories are included only for departments that can
/// actually act on them, so a department is never handed data outside its
/// own mandate.
class DepartmentContextBuilder {
  const DepartmentContextBuilder();

  static const Set<Department> _productDepartments = {
    Department.executive,
    Department.marketing,
    Department.engineering,
    Department.sales,
  };

  static const Set<Department> _assetDepartments = {
    Department.executive,
    Department.marketing,
  };

  static const Set<Department> _serviceDepartments = {
    Department.executive,
    Department.engineering,
  };

  static const Set<Department> _websiteDepartments = {
    Department.executive,
    Department.marketing,
  };

  static const Set<Department> _socialDepartments = {
    Department.executive,
    Department.marketing,
  };

  static const Set<Department> _analyticsDepartments = {
    Department.executive,
    Department.marketing,
  };

  /// Departments other than Executive only see Knowledge documents whose
  /// content matches their own vocabulary; Executive needs full visibility
  /// to spot cross-department blockers, so it sees every document.
  static const Map<Department, List<String>> _knowledgeKeywords = {
    Department.marketing: [
      'marketing',
      'seo',
      'brand',
      'campaign',
      'social',
      'competitor',
      'advertising',
      'content',
      'market research',
      'audience',
    ],
    Department.engineering: [
      'engineering',
      'architecture',
      'infrastructure',
      'repository',
      'developer',
      'technical',
      'backend',
      'frontend',
      'api',
      'flutter',
      'dart',
      'code',
    ],
    Department.sales: [
      'sales',
      'lead',
      'crm',
      'pipeline',
      'partnership',
      'deal',
      'prospect',
    ],
    Department.operations: [
      'operations',
      'workflow',
      'process',
      'automation',
      'logistics',
      'support',
    ],
    Department.finance: [
      'finance',
      'billing',
      'subscription',
      'payment',
      'revenue',
      'invoice',
      'budget',
      'cost',
      'accounting',
    ],
  };

  List<DepartmentContext> buildAll(CompanyContext context) => [
    for (final department in Department.values) build(department, context),
  ];

  DepartmentContext build(Department department, CompanyContext context) {
    final relevantCategories = <String>{'Company', 'Knowledge'};

    if (_productDepartments.contains(department)) {
      relevantCategories.add('Products');
    }
    if (_assetDepartments.contains(department)) {
      relevantCategories.add('Assets');
    }
    if (_serviceDepartments.contains(department)) {
      relevantCategories.add('Services');
    }
    if (_websiteDepartments.contains(department)) {
      relevantCategories.add('Websites');
    }
    if (_socialDepartments.contains(department)) {
      relevantCategories.add('Social');
    }
    if (_analyticsDepartments.contains(department)) {
      relevantCategories.add('Analytics');
    }

    return DepartmentContext(
      department: department,
      relevantCategories: relevantCategories,
      company: context.company,
      knowledge: _relevantKnowledge(department, context.knowledge),
      products: _productDepartments.contains(department)
          ? context.products
          : const [],
      assets: _assetDepartments.contains(department)
          ? context.assets
          : const [],
      services: _serviceDepartments.contains(department)
          ? context.services
          : const [],
      websites: _websiteDepartments.contains(department)
          ? context.websites
          : const [],
      social: _socialDepartments.contains(department)
          ? context.social
          : const [],
      analytics: _analyticsDepartments.contains(department)
          ? context.analytics
          : const [],
    );
  }

  List<String> _relevantKnowledge(
    Department department,
    List<String> knowledge,
  ) {
    if (department == Department.executive) {
      return knowledge;
    }

    final keywords = _knowledgeKeywords[department] ?? const [];

    return [
      for (final entry in knowledge)
        if (keywords.any((keyword) => entry.toLowerCase().contains(keyword)))
          entry,
    ];
  }
}
