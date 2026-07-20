import 'package:pharos_ai_runtime/data/data_snapshot.dart';
import 'package:pharos_ai_runtime/data/data_source.dart';

/// Owns every available DataSource and refreshes them into one shared
/// DataSnapshot, sequentially, in the given order. No parallel
/// execution.
class DataSourceRegistry {
  const DataSourceRegistry({required this.sources});

  final List<DataSource> sources;

  Future<void> refreshAll(DataSnapshot snapshot) async {
    for (final source in sources) {
      await source.refresh(snapshot);
    }
  }
}
