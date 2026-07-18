import 'package:pharos_ai_runtime/memory/memory_author.dart';
import 'package:pharos_ai_runtime/memory/memory_entry.dart';
import 'package:test/test.dart';

void main() {
  test('MemoryEntry stores id, timestamp, author, and content', () {
    final timestamp = DateTime(2026, 7, 19, 12, 0, 0);
    final entry = MemoryEntry(
      id: 'entry-1',
      timestamp: timestamp,
      author: MemoryAuthor.user,
      content: 'How does our commission engine work?',
    );

    expect(entry.id, 'entry-1');
    expect(entry.timestamp, timestamp);
    expect(entry.author, MemoryAuthor.user);
    expect(entry.content, 'How does our commission engine work?');
  });

  test('MemoryEntry supports all three authors', () {
    expect(MemoryAuthor.values, [
      MemoryAuthor.user,
      MemoryAuthor.employee,
      MemoryAuthor.tool,
    ]);
  });
}
