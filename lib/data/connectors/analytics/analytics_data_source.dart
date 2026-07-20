import 'package:pharos_ai_runtime/data/data_snapshot.dart';
import 'package:pharos_ai_runtime/data/data_source.dart';

/// Placeholder connector for analytics data (for example Firebase
/// Analytics, GA4, Search Console). No real integration yet —
/// populates nothing until it is implemented.
class AnalyticsDataSource implements DataSource {
  const AnalyticsDataSource({required this.workspaceRoot});

  /// The HQ workspace root directory. Where and how analytics data
  /// lives under it is this connector's own concern, hidden from the
  /// rest of the runtime.
  final String workspaceRoot;

  @override
  String get id => 'analytics';

  @override
  Future<void> refresh(DataSnapshot snapshot) async {
    // Placeholder only — no real analytics integration yet.
  }
}
