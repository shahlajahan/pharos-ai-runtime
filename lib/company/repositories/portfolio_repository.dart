import 'package:pharos_ai_runtime/company/portfolio/portfolio.dart';

/// Defines how the Portfolio aggregate root is retrieved and persisted.
/// This is a contract only: no implementation, no storage, no caching,
/// no networking, no serialization.
abstract interface class PortfolioRepository {
  Future<Portfolio?> load();

  Future<void> save(Portfolio portfolio);
}
