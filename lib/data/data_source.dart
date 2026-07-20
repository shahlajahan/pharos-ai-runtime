import 'package:pharos_ai_runtime/data/data_snapshot.dart';

/// A connector to one real-world company system (CRM, social media,
/// analytics, ...). A DataSource never talks to another DataSource, and
/// never depends on how any other DataSource loads or stores its own
/// data — it only knows how to populate its own section of the shared
/// [DataSnapshot].
abstract interface class DataSource {
  String get id;

  Future<void> refresh(DataSnapshot snapshot);
}
