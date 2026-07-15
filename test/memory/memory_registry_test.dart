import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/memory/memory.dart';
import 'package:pharos_ai_runtime/memory/memory_context.dart';
import 'package:pharos_ai_runtime/memory/memory_registry.dart';
import 'package:test/test.dart';

class _FakeMemory extends Memory {
  @override
  Future<Result> store(MemoryContext context) async =>
      Result.success('stored');

  @override
  Future<Result> retrieve(MemoryContext context) async =>
      Result.success('retrieved');
}

void main() {
  test('MemoryRegistry defaults to empty and resolves nothing', () {
    const registry = MemoryRegistry();

    expect(registry.find('memory-1'), isNull);
  });

  test(
    'MemoryRegistry resolves a Memory registered via constructor injection',
    () {
      final memory = _FakeMemory();
      final registry = MemoryRegistry(memories: {'memory-1': memory});

      expect(registry.find('memory-1'), same(memory));
      expect(registry.find('missing'), isNull);
    },
  );
}
