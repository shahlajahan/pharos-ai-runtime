import 'package:pharos_ai_runtime/memory/memory_entry.dart';
import 'package:pharos_ai_runtime/memory/memory_store.dart';

/// In-memory MemoryStore implementation. No persistence to disk — entries
/// live only as long as this instance does.
class InMemoryMemoryStore implements MemoryStore {
  final List<MemoryEntry> _entries = [];

  @override
  Future<void> append(MemoryEntry entry) async {
    _entries.add(entry);
  }

  @override
  Future<List<MemoryEntry>> readAll() async {
    return List.unmodifiable(_entries);
  }
}
