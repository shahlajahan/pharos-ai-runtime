import 'package:pharos_ai_runtime/company/department.dart';
import 'package:pharos_ai_runtime/company/department_facts.dart';
import 'package:pharos_ai_runtime/knowledge/fact_type.dart';
import 'package:pharos_ai_runtime/knowledge/knowledge_graph.dart';

/// Builds one DepartmentFacts per Department from a single KnowledgeGraph.
/// Replaces document-based department contexts: departments now reason
/// over CompanyFacts, never over CompanyDocuments or markdown.
class DepartmentFactBuilder {
  const DepartmentFactBuilder();

  /// The fact types each department has a mandate over. Executive keeps
  /// every type, since its job is spotting cross-department blockers.
  static const Map<Department, Set<FactType>> _relevantTypes = {
    Department.executive: {
      FactType.company,
      FactType.capability,
      FactType.product,
      FactType.service,
      FactType.website,
      FactType.domain,
      FactType.brandAsset,
      FactType.mediaAsset,
      FactType.socialAccount,
      FactType.analyticsPlatform,
      FactType.repository,
      FactType.infrastructure,
      FactType.competitor,
      FactType.targetMarket,
      FactType.technology,
      FactType.subscription,
      FactType.paymentProvider,
      FactType.workflow,
      FactType.policy,
    },
    Department.marketing: {
      FactType.capability,
      FactType.product,
      FactType.website,
      FactType.domain,
      FactType.brandAsset,
      FactType.mediaAsset,
      FactType.socialAccount,
      FactType.analyticsPlatform,
      FactType.competitor,
      FactType.targetMarket,
    },
    Department.engineering: {
      FactType.capability,
      FactType.product,
      FactType.service,
      FactType.repository,
      FactType.infrastructure,
      FactType.technology,
      FactType.policy,
    },
    Department.sales: {
      FactType.capability,
      FactType.product,
      FactType.competitor,
      FactType.targetMarket,
    },
    Department.finance: {
      FactType.capability,
      FactType.subscription,
      FactType.paymentProvider,
      FactType.policy,
    },
    Department.operations: {
      FactType.capability,
      FactType.workflow,
      FactType.policy,
    },
  };

  List<DepartmentFacts> buildAll(KnowledgeGraph graph) => [
    for (final department in Department.values) build(department, graph),
  ];

  DepartmentFacts build(Department department, KnowledgeGraph graph) {
    final relevantTypes = _relevantTypes[department] ?? const {};
    final facts = graph
        .factsByDepartment(department)
        .where((fact) => relevantTypes.contains(fact.type))
        .toList();

    final knownTypes = [
      for (final type in relevantTypes)
        if (facts.any((fact) => fact.type == type)) type,
    ];

    final missingTypes = [
      for (final type in relevantTypes)
        if (!facts.any((fact) => fact.type == type)) type,
    ];

    return DepartmentFacts(
      department: department,
      facts: facts,
      knownTypes: knownTypes,
      missingTypes: missingTypes,
    );
  }
}
