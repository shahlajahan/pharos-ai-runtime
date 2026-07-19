import 'package:pharos_ai_runtime/memory/in_memory_memory_store.dart';
import 'package:pharos_ai_runtime/memory/memory_author.dart';
import 'package:pharos_ai_runtime/memory/memory_entry.dart';
import 'package:pharos_ai_runtime/memory/memory_store.dart';
import 'package:pharos_ai_runtime/tooling/memory_search_tool.dart';
import 'package:pharos_ai_runtime/tooling/tool_context.dart';
import 'package:test/test.dart';

Future<MemoryStore> _storeWith(List<MemoryEntry> entries) async {
  final store = InMemoryMemoryStore();

  for (final entry in entries) {
    await store.append(entry);
  }

  return store;
}

MemoryEntry _entry(String id, MemoryAuthor author, String content) =>
    MemoryEntry(
      id: id,
      timestamp: DateTime(2026),
      author: author,
      content: content,
    );

void main() {
  test('id is "memory_search"', () {
    final tool = MemorySearchTool(store: InMemoryMemoryStore());

    expect(tool.id, 'memory_search');
  });

  test('execute() matches by keyword in content', () async {
    final store = await _storeWith([
      _entry('1', MemoryAuthor.user, 'My preferred database is PostgreSQL.'),
      _entry('2', MemoryAuthor.employee, 'Got it, noted.'),
    ]);
    final tool = MemorySearchTool(store: store);

    final result = await tool.execute(
      const ToolContext(
        toolId: 'memory_search',
        arguments: '{"query":"database"}',
      ),
    );

    expect(result.success, isTrue);
    expect(result.message, contains('PostgreSQL'));
    expect(result.message, isNot(contains('Got it, noted.')));
  });

  test('execute() matching is case-insensitive', () async {
    final store = await _storeWith([
      _entry('1', MemoryAuthor.user, 'My preferred database is PostgreSQL.'),
    ]);
    final tool = MemorySearchTool(store: store);

    final result = await tool.execute(
      const ToolContext(
        toolId: 'memory_search',
        arguments: '{"query":"POSTGRESQL"}',
      ),
    );

    expect(result.success, isTrue);
    expect(result.message, contains('PostgreSQL'));
  });

  test('execute() returns every matching entry, joined, in chronological '
      'order, when more than one entry matches', () async {
    final store = await _storeWith([
      _entry('1', MemoryAuthor.user, 'My preferred database is PostgreSQL.'),
      _entry('2', MemoryAuthor.employee, 'Noted your preference.'),
      _entry('3', MemoryAuthor.user, 'Actually, use the database sparingly.'),
    ]);
    final tool = MemorySearchTool(store: store);

    final result = await tool.execute(
      const ToolContext(
        toolId: 'memory_search',
        arguments: '{"query":"database"}',
      ),
    );

    expect(result.success, isTrue);
    final firstIndex = result.message.indexOf('PostgreSQL');
    final secondIndex = result.message.indexOf('use the database sparingly');
    expect(firstIndex, greaterThanOrEqualTo(0));
    expect(secondIndex, greaterThan(firstIndex));
    expect(result.message, isNot(contains('Noted your preference.')));
  });

  test('execute() succeeds with a "no matching memory" message when nothing '
      'matches', () async {
    final store = await _storeWith([
      _entry('1', MemoryAuthor.user, 'My preferred database is PostgreSQL.'),
    ]);
    final tool = MemorySearchTool(store: store);

    final result = await tool.execute(
      const ToolContext(
        toolId: 'memory_search',
        arguments: '{"query":"quantum computing"}',
      ),
    );

    expect(result.success, isTrue);
    expect(result.message, contains('No matching memory found'));
  });

  test('execute() only ever searches the MemoryStore it was constructed '
      'with, never another conversation\'s entries', () async {
    final otherStore = await _storeWith([
      _entry('1', MemoryAuthor.user, 'My preferred database is PostgreSQL.'),
    ]);
    final store = await _storeWith([
      _entry('1', MemoryAuthor.user, 'Unrelated content.'),
    ]);
    final tool = MemorySearchTool(store: store);

    final result = await tool.execute(
      const ToolContext(
        toolId: 'memory_search',
        arguments: '{"query":"database"}',
      ),
    );

    expect(result.success, isTrue);
    expect(result.message, contains('No matching memory found'));
    // otherStore is never touched by this tool instance.
    expect(await otherStore.readAll(), hasLength(1));
  });

  test('execute() returns Result.failure for invalid JSON arguments', () async {
    final tool = MemorySearchTool(store: InMemoryMemoryStore());

    final result = await tool.execute(
      const ToolContext(toolId: 'memory_search', arguments: 'not json'),
    );

    expect(result.success, isFalse);
  });

  test(
    'execute() returns Result.failure when arguments is not a JSON object',
    () async {
      final tool = MemorySearchTool(store: InMemoryMemoryStore());

      final result = await tool.execute(
        const ToolContext(toolId: 'memory_search', arguments: '[]'),
      );

      expect(result.success, isFalse);
    },
  );

  test('execute() returns Result.failure when "query" is missing', () async {
    final tool = MemorySearchTool(store: InMemoryMemoryStore());

    final result = await tool.execute(
      const ToolContext(toolId: 'memory_search', arguments: '{}'),
    );

    expect(result.success, isFalse);
  });

  test('execute() returns Result.failure when "query" is empty', () async {
    final tool = MemorySearchTool(store: InMemoryMemoryStore());

    final result = await tool.execute(
      const ToolContext(toolId: 'memory_search', arguments: '{"query":""}'),
    );

    expect(result.success, isFalse);
  });

  test('execute() does not modify the MemoryStore', () async {
    final store = await _storeWith([
      _entry('1', MemoryAuthor.user, 'My preferred database is PostgreSQL.'),
    ]);
    final tool = MemorySearchTool(store: store);

    await tool.execute(
      const ToolContext(
        toolId: 'memory_search',
        arguments: '{"query":"database"}',
      ),
    );

    expect(await store.readAll(), hasLength(1));
  });
}
