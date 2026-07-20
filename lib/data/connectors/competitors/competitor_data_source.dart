import 'package:pharos_ai_runtime/data/data_snapshot.dart';
import 'package:pharos_ai_runtime/data/data_source.dart';

/// Placeholder connector for competitor monitoring. No real integration
/// yet — populates nothing until it is implemented.
class CompetitorDataSource implements DataSource {
  const CompetitorDataSource({required this.workspaceRoot});

  /// The HQ workspace root directory. Where and how competitor data
  /// lives under it is this connector's own concern, hidden from the
  /// rest of the runtime.
  final String workspaceRoot;

  @override
  String get id => 'competitors';

  @override
  Future<void> refresh(DataSnapshot snapshot) async {
    // Placeholder only — no real competitor monitoring integration yet.
  }
}
