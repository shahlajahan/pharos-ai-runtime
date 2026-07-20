import 'package:pharos_ai_runtime/company/department.dart';
import 'package:pharos_ai_runtime/knowledge/company_fact.dart';
import 'package:pharos_ai_runtime/knowledge/fact_type.dart';

/// Stores every CompanyFact the Runtime currently knows. Pure storage
/// and querying: no prompting, no recommendations, no reasoning.
class KnowledgeGraph {
  const KnowledgeGraph({required this.facts});

  final List<CompanyFact> facts;

  List<CompanyFact> products() => factsByType(FactType.product);

  List<CompanyFact> capabilities() => factsByType(FactType.capability);

  List<CompanyFact> socialAccounts() => factsByType(FactType.socialAccount);

  List<CompanyFact> websites() => factsByType(FactType.website);

  List<CompanyFact> competitors() => factsByType(FactType.competitor);

  List<CompanyFact> technologies() => factsByType(FactType.technology);

  List<CompanyFact> marketingAssets() => [
    ...factsByType(FactType.brandAsset),
    ...factsByType(FactType.mediaAsset),
  ];

  List<CompanyFact> engineeringAssets() => [
    ...factsByType(FactType.repository),
    ...factsByType(FactType.infrastructure),
    ...factsByType(FactType.technology),
  ];

  List<CompanyFact> factsByType(FactType type) =>
      facts.where((fact) => fact.type == type).toList();

  List<CompanyFact> factsByDepartment(Department department) =>
      facts.where((fact) => fact.visibleTo.contains(department)).toList();
}
