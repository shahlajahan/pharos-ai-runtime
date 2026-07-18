import 'package:pharos_ai_runtime/memory/memory_author.dart';

/// One immutable, append-only record in a ConversationMemory.
class MemoryEntry {
  const MemoryEntry({
    required this.id,
    required this.timestamp,
    required this.author,
    required this.content,
  });

  final String id;
  final DateTime timestamp;
  final MemoryAuthor author;
  final String content;
}
