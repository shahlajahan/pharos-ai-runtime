import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/memory/memory.dart';
import 'package:pharos_ai_runtime/memory/memory_context.dart';
import 'package:pharos_ai_runtime/memory/memory_invoker.dart';
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

class _ThrowingMemory extends Memory {
  @override
  Future<Result> store(MemoryContext context) async {
    throw StateError('memory boom');
  }

  @override
  Future<Result> retrieve(MemoryContext context) async {
    throw StateError('memory boom');
  }
}

class _CapturingMemory extends Memory {
  MemoryContext? capturedContext;

  @override
  Future<Result> store(MemoryContext context) async {
    capturedContext = context;
    return Result.success('stored');
  }

  @override
  Future<Result> retrieve(MemoryContext context) async {
    capturedContext = context;
    return Result.success('retrieved');
  }
}

void main() {
  test(
    'MemoryInvoker invokes a registered Memory\'s store() and retrieve()',
    () async {
      final memory = _FakeMemory();
      final invoker = MemoryInvoker(
        registry: MemoryRegistry(memories: {'memory-1': memory}),
      );

      final storeResult = await invoker.store('memory-1', 'key-1');
      final retrieveResult = await invoker.retrieve('memory-1', 'key-1');

      expect(storeResult.success, isTrue);
      expect(storeResult.message, 'stored');
      expect(retrieveResult.success, isTrue);
      expect(retrieveResult.message, 'retrieved');
    },
  );

  test(
    'MemoryInvoker returns Result.failure for an unknown memory id',
    () async {
      final invoker = MemoryInvoker(registry: const MemoryRegistry());

      final storeResult = await invoker.store('missing', 'key-1');
      final retrieveResult = await invoker.retrieve('missing', 'key-1');

      expect(storeResult.success, isFalse);
      expect(storeResult.message, contains('missing'));
      expect(retrieveResult.success, isFalse);
      expect(retrieveResult.message, contains('missing'));
    },
  );

  test(
    'MemoryInvoker catches memory exceptions and returns Result.failure',
    () async {
      final memory = _ThrowingMemory();
      final invoker = MemoryInvoker(
        registry: MemoryRegistry(memories: {'memory-1': memory}),
      );

      final storeResult = await invoker.store('memory-1', 'key-1');
      final retrieveResult = await invoker.retrieve('memory-1', 'key-1');

      expect(storeResult.success, isFalse);
      expect(storeResult.message, contains('memory boom'));
      expect(retrieveResult.success, isFalse);
      expect(retrieveResult.message, contains('memory boom'));
    },
  );

  test('MemoryInvoker passes a MemoryContext with the given key', () async {
    final memory = _CapturingMemory();
    final invoker = MemoryInvoker(
      registry: MemoryRegistry(memories: {'memory-1': memory}),
    );

    await invoker.retrieve('memory-1', 'key-1');

    expect(memory.capturedContext, isNotNull);
    expect(memory.capturedContext!.key, 'key-1');
  });

  test(
    'MemoryInvoker resolves the Memory by memoryId, independent of key',
    () async {
      final memory = _CapturingMemory();
      final invoker = MemoryInvoker(
        registry: MemoryRegistry(memories: {'memory-1': memory}),
      );

      final result = await invoker.store('memory-1', 'unrelated-key');

      expect(result.success, isTrue);
      expect(memory.capturedContext!.key, 'unrelated-key');
    },
  );
}
