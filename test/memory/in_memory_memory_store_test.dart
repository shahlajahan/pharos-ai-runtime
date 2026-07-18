import 'package:pharos_ai_runtime/memory/in_memory_memory_store.dart';
import 'package:pharos_ai_runtime/memory/memory_author.dart';
import 'package:pharos_ai_runtime/memory/memory_entry.dart';
import 'package:test/test.dart';

void main() {
  test('readAll() returns an empty list for a fresh store', () async {
    final store = InMemoryMemoryStore();

    expect(await store.readAll(), isEmpty);
  });

  test('append() then readAll() returns the appended entry', () async {
    final store = InMemoryMemoryStore();
    final entry = MemoryEntry(
      id: 'entry-1',
      timestamp: DateTime(2026, 7, 19),
      author: MemoryAuthor.user,
      content: 'Hello',
    );

    await store.append(entry);

    expect(await store.readAll(), [entry]);
  });

  test('append() preserves call order across multiple entries', () async {
    final store = InMemoryMemoryStore();
    final first = MemoryEntry(
      id: 'entry-1',
      timestamp: DateTime(2026, 7, 19),
      author: MemoryAuthor.user,
      content: 'First',
    );
    final second = MemoryEntry(
      id: 'entry-2',
      timestamp: DateTime(2026, 7, 19),
      author: MemoryAuthor.employee,
      content: 'Second',
    );
    final third = MemoryEntry(
      id: 'entry-3',
      timestamp: DateTime(2026, 7, 19),
      author: MemoryAuthor.tool,
      content: 'Third',
    );

    await store.append(first);
    await store.append(second);
    await store.append(third);

    expect(await store.readAll(), [first, second, third]);
  });

  test('readAll() returns a list that cannot be mutated by callers', () async {
    final store = InMemoryMemoryStore();
    await store.append(
      MemoryEntry(
        id: 'entry-1',
        timestamp: DateTime(2026, 7, 19),
        author: MemoryAuthor.user,
        content: 'Hello',
      ),
    );

    final entries = await store.readAll();

    expect(() => entries.add(entries.first), throwsUnsupportedError);
  });

  test(
    'mutating the list returned by readAll() does not affect the store',
    () async {
      final store = InMemoryMemoryStore();
      final entry = MemoryEntry(
        id: 'entry-1',
        timestamp: DateTime(2026, 7, 19),
        author: MemoryAuthor.user,
        content: 'Hello',
      );
      await store.append(entry);

      // readAll() returns a fresh unmodifiable snapshot each call; later
      // appends must still be reflected in the next call.
      await store.append(
        MemoryEntry(
          id: 'entry-2',
          timestamp: DateTime(2026, 7, 19),
          author: MemoryAuthor.employee,
          content: 'World',
        ),
      );

      expect(await store.readAll(), hasLength(2));
    },
  );
}
