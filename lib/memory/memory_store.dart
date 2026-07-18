import 'package:pharos_ai_runtime/memory/memory_entry.dart';

/// Append-only storage for MemoryEntry records. No summarization, no
/// pruning, no search — just append and read back everything.
abstract class MemoryStore {
  Future<void> append(MemoryEntry entry);

  Future<List<MemoryEntry>> readAll();
}
