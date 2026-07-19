import 'package:pharos_ai_runtime/company/governance/company_governance.dart';
import 'package:pharos_ai_runtime/company/identity/company_configuration.dart';
import 'package:pharos_ai_runtime/company/identity/company_identity.dart';
import 'package:pharos_ai_runtime/company/knowledge/knowledge.dart';
import 'package:pharos_ai_runtime/company/metrics/metrics.dart';
import 'package:pharos_ai_runtime/company/organization/organization.dart';
import 'package:pharos_ai_runtime/company/portfolio/portfolio.dart';
import 'package:pharos_ai_runtime/company/resources/resources.dart';

/// The business root of Pharos HQ: a uniquely identifiable organization,
/// expressed as a small, stable set of business areas. Company is not a
/// Workflow, not Runtime, and not HQ — it owns no execution, no business
/// logic, and no persistence. Individual business objects (Departments,
/// Products, Projects, financial resources, ...) live behind their
/// owning area (Organization, Portfolio, Resources, ...) rather than
/// directly on Company, so Company itself stays a small, stable
/// aggregate root as the organization grows.
class Company {
  const Company({
    required this.identity,
    required this.configuration,
    required this.governance,
    required this.organization,
    required this.portfolio,
    required this.resources,
    required this.knowledge,
    required this.metrics,
  });

  final CompanyIdentity identity;
  final CompanyConfiguration configuration;
  final CompanyGovernance governance;
  final Organization organization;
  final Portfolio portfolio;
  final Resources resources;
  final Knowledge knowledge;
  final Metrics metrics;
}
