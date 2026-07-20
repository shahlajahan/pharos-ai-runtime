import 'package:pharos_ai_runtime/data/data_snapshot.dart';
import 'package:pharos_ai_runtime/data/data_source.dart';

/// Placeholder connector for trend data (for example Google Trends). No
/// real integration yet — populates nothing until it is implemented.
class TrendsDataSource implements DataSource {
  const TrendsDataSource({required this.workspaceRoot});

  /// The HQ workspace root directory. Where and how trend data lives
  /// under it is this connector's own concern, hidden from the rest of
  /// the runtime.
  final String workspaceRoot;

  @override
  String get id => 'trends';

  @override
  Future<void> refresh(DataSnapshot snapshot) async {
    // Placeholder only — no real trends integration yet.
  }
}
