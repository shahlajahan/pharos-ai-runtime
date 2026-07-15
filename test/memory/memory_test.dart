import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/memory/memory.dart';
import 'package:pharos_ai_runtime/memory/memory_context.dart';
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
  test(
    'Memory exposes store(context) and retrieve(context) returning a Result',
    () async {
      final memory = _FakeMemory();
      const context = MemoryContext(key: 'key-1');

      final storeResult = await memory.store(context);
      final retrieveResult = await memory.retrieve(context);

      expect(storeResult.success, isTrue);
      expect(storeResult.message, 'stored');
      expect(retrieveResult.success, isTrue);
      expect(retrieveResult.message, 'retrieved');
    },
  );
}
