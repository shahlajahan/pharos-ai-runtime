import 'package:pharos_ai_runtime/data/data_snapshot.dart';
import 'package:pharos_ai_runtime/data/data_source.dart';

/// Placeholder connector for social media data. No real integration yet
/// — populates nothing until social APIs are implemented.
class SocialDataSource implements DataSource {
  const SocialDataSource({required this.workspaceRoot});

  /// The HQ workspace root directory. Where and how social data lives
  /// under it is this connector's own concern, hidden from the rest of
  /// the runtime.
  final String workspaceRoot;

  @override
  String get id => 'social';

  @override
  Future<void> refresh(DataSnapshot snapshot) async {
    // Placeholder only — no real social integration yet.
  }
}
