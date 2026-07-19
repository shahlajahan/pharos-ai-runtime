import 'package:pharos_ai_runtime/company/company.dart';

/// Defines how the Company is retrieved and persisted. This is a
/// contract only: no implementation, no storage, no singleton, no
/// dependency injection wiring lives here.
abstract class CompanyRepository {
  Future<Company?> load();

  Future<void> save(Company company);
}
