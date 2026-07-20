import 'package:pharos_ai_runtime/data/data_snapshot.dart';
import 'package:pharos_ai_runtime/data/data_source.dart';

/// Placeholder connector for industry news. No real integration yet —
/// populates nothing until it is implemented.
class NewsDataSource implements DataSource {
  const NewsDataSource({required this.workspaceRoot});

  /// The HQ workspace root directory. Where and how news data lives
  /// under it is this connector's own concern, hidden from the rest of
  /// the runtime.
  final String workspaceRoot;

  @override
  String get id => 'news';

  @override
  Future<void> refresh(DataSnapshot snapshot) async {
    // Placeholder only — no real news integration yet.
  }
}
