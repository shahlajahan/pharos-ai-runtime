import 'package:pharos_ai_runtime/company/company.dart';

/// Defines how the Company aggregate root is retrieved and persisted.
/// This is a contract only: no implementation, no storage, no caching,
/// no networking, no serialization.
abstract interface class CompanyRepository {
  Future<Company?> load();

  Future<void> save(Company company);
}
