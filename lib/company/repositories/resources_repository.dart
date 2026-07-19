import 'package:pharos_ai_runtime/company/resources/resources.dart';

/// Defines how the Resources aggregate root is retrieved and persisted.
/// This is a contract only: no implementation, no storage, no caching,
/// no networking, no serialization.
abstract interface class ResourcesRepository {
  Future<Resources?> load();

  Future<void> save(Resources resources);
}
