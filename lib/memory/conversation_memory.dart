import 'package:pharos_ai_runtime/memory/in_memory_memory_store.dart';
import 'package:pharos_ai_runtime/memory/memory_author.dart';
import 'package:pharos_ai_runtime/memory/memory_entry.dart';
import 'package:pharos_ai_runtime/memory/memory_store.dart';
import 'package:pharos_ai_runtime/models/conversation.dart';

/// An Employee's personal working memory for one Conversation.
///
/// Private to the conversation, dynamic, and append-only — separate from
/// Knowledge, which is shared by the organization, static, and read-only.
/// Every new UserMessage, AssistantMessage, and ToolMessage produced
/// during execution is recorded here, in order. SystemMessages are not
/// recorded: Memory tracks the conversation's turns, not the static
/// system prompt.
class ConversationMemory {
  ConversationMemory({MemoryStore? store, DateTime Function()? clock})
    : store = store ?? InMemoryMemoryStore(),
      _clock = clock ?? DateTime.now;

  final MemoryStore store;
  final DateTime Function() _clock;
  int _sequence = 0;

  /// Records [message] as a new MemoryEntry, preserving call order. A
  /// no-op for SystemMessage.
  Future<void> record(Message message) async {
    final author = _authorOf(message);

    if (author == null) {
      return;
    }

    _sequence++;

    await store.append(
      MemoryEntry(
        id: 'memory-entry-$_sequence',
        timestamp: _clock(),
        author: author,
        content: _contentOf(message),
      ),
    );
  }

  Future<List<MemoryEntry>> readAll() => store.readAll();

  MemoryAuthor? _authorOf(Message message) {
    if (message is UserMessage) {
      return MemoryAuthor.user;
    }

    if (message is AssistantMessage) {
      return MemoryAuthor.employee;
    }

    if (message is ToolMessage) {
      return MemoryAuthor.tool;
    }

    return null;
  }

  String _contentOf(Message message) {
    if (message is UserMessage) {
      return message.content;
    }

    if (message is AssistantMessage) {
      return message.content;
    }

    if (message is ToolMessage) {
      return message.content;
    }

    return '';
  }
}
