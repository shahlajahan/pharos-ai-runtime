import 'package:pharos_ai_runtime/company/organization/organization.dart';

/// Defines how the Organization aggregate root is retrieved and
/// persisted. This is a contract only: no implementation, no storage, no
/// caching, no networking, no serialization.
abstract interface class OrganizationRepository {
  Future<Organization?> load();

  Future<void> save(Organization organization);
}
