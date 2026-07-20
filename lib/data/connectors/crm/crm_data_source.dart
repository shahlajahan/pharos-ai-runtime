import 'package:pharos_ai_runtime/data/data_snapshot.dart';
import 'package:pharos_ai_runtime/data/data_source.dart';

/// Placeholder connector for the company's CRM. No real integration yet
/// — populates nothing until CRM parsing is implemented.
class CrmDataSource implements DataSource {
  const CrmDataSource({required this.workspaceRoot});

  /// The HQ workspace root directory. Where and how the CRM data lives
  /// under it (a file, a spreadsheet, an API) is this connector's own
  /// concern, hidden from the rest of the runtime.
  final String workspaceRoot;

  @override
  String get id => 'crm';

  @override
  Future<void> refresh(DataSnapshot snapshot) async {
    // Placeholder only — no real CRM integration yet.
  }
}
