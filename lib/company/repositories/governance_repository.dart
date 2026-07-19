import 'package:pharos_ai_runtime/company/governance/company_governance.dart';

/// Defines how the CompanyGovernance aggregate root is retrieved and
/// persisted. This is a contract only: no implementation, no storage, no
/// caching, no networking, no serialization.
abstract interface class GovernanceRepository {
  Future<CompanyGovernance?> load();

  Future<void> save(CompanyGovernance governance);
}
