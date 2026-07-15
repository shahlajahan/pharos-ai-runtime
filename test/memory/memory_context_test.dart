import 'package:pharos_ai_runtime/memory/memory_context.dart';
import 'package:test/test.dart';

void main() {
  test('MemoryContext stores only key', () {
    const context = MemoryContext(key: 'key-1');

    expect(context.key, 'key-1');
  });
}
