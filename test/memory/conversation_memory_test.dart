import 'package:pharos_ai_runtime/memory/conversation_memory.dart';
import 'package:pharos_ai_runtime/memory/memory_author.dart';
import 'package:pharos_ai_runtime/memory/memory_entry.dart';
import 'package:pharos_ai_runtime/memory/memory_store.dart';
import 'package:pharos_ai_runtime/models/conversation.dart';
import 'package:test/test.dart';

class _SpyMemoryStore implements MemoryStore {
  final List<MemoryEntry> appended = [];

  @override
  Future<void> append(MemoryEntry entry) async {
    appended.add(entry);
  }

  @override
  Future<List<MemoryEntry>> readAll() async => List.unmodifiable(appended);
}

void main() {
  test('ConversationMemory starts empty', () async {
    final memory = ConversationMemory();

    expect(await memory.readAll(), isEmpty);
  });

  test('record() appends a UserMessage as author user', () async {
    final memory = ConversationMemory();

    await memory.record(const UserMessage(content: 'How does it work?'));

    final entries = await memory.readAll();
    expect(entries, hasLength(1));
    expect(entries.single.author, MemoryAuthor.user);
    expect(entries.single.content, 'How does it work?');
  });

  test('record() appends an AssistantMessage as author employee', () async {
    final memory = ConversationMemory();

    await memory.record(const AssistantMessage(content: 'Here is the answer.'));

    final entries = await memory.readAll();
    expect(entries, hasLength(1));
    expect(entries.single.author, MemoryAuthor.employee);
    expect(entries.single.content, 'Here is the answer.');
  });

  test('record() appends a ToolMessage as author tool', () async {
    final memory = ConversationMemory();

    await memory.record(
      const ToolMessage(
        toolCallId: 'call_1',
        toolName: 'knowledge_search',
        content: 'Matching document content.',
      ),
    );

    final entries = await memory.readAll();
    expect(entries, hasLength(1));
    expect(entries.single.author, MemoryAuthor.tool);
    expect(entries.single.content, 'Matching document content.');
  });

  test('record() does not append a SystemMessage', () async {
    final memory = ConversationMemory();

    await memory.record(const SystemMessage(content: 'You are the CEO.'));

    expect(await memory.readAll(), isEmpty);
  });

  test(
    'record() preserves message order across a full conversation turn',
    () async {
      final memory = ConversationMemory();

      await memory.record(const SystemMessage(content: 'You are the CEO.'));
      await memory.record(const UserMessage(content: 'What is the plan?'));
      await memory.record(const AssistantMessage(content: '', toolCalls: []));
      await memory.record(
        const ToolMessage(
          toolCallId: 'call_1',
          toolName: 'knowledge_search',
          content: 'The plan is documented here.',
        ),
      );
      await memory.record(
        const AssistantMessage(content: 'Here is the plan: ...'),
      );

      final entries = await memory.readAll();

      // SystemMessage is skipped, so 4 entries remain, in order.
      expect(entries, hasLength(4));
      expect(entries[0].author, MemoryAuthor.user);
      expect(entries[0].content, 'What is the plan?');
      expect(entries[1].author, MemoryAuthor.employee);
      expect(entries[1].content, '');
      expect(entries[2].author, MemoryAuthor.tool);
      expect(entries[2].content, 'The plan is documented here.');
      expect(entries[3].author, MemoryAuthor.employee);
      expect(entries[3].content, 'Here is the plan: ...');
    },
  );

  test('record() assigns each entry a unique, sequential id', () async {
    final memory = ConversationMemory();

    await memory.record(const UserMessage(content: 'First'));
    await memory.record(const AssistantMessage(content: 'Second'));

    final entries = await memory.readAll();

    expect(entries[0].id, isNot(entries[1].id));
  });

  test('record() stamps each entry with the current time', () async {
    final fixedTime = DateTime(2026, 7, 19, 9, 30);
    final memory = ConversationMemory(clock: () => fixedTime);

    await memory.record(const UserMessage(content: 'Hello'));

    final entries = await memory.readAll();
    expect(entries.single.timestamp, fixedTime);
  });

  test('ConversationMemory records into the given MemoryStore', () async {
    final store = _SpyMemoryStore();
    final memory = ConversationMemory(store: store);

    await memory.record(const UserMessage(content: 'Hello'));

    expect(store.appended, hasLength(1));
    expect(store.appended.single.content, 'Hello');
  });

  test(
    'ConversationMemory defaults to an in-memory store when none is given',
    () async {
      final memory = ConversationMemory();

      await memory.record(const UserMessage(content: 'Hello'));

      // No exception, and the entry is retrievable through this
      // ConversationMemory's own readAll(), proving a working default
      // store was created automatically.
      expect(await memory.readAll(), hasLength(1));
    },
  );
}
