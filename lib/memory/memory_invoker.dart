import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/memory/memory.dart';
import 'package:pharos_ai_runtime/memory/memory_context.dart';
import 'package:pharos_ai_runtime/memory/memory_registry.dart';

class MemoryInvoker {
  const MemoryInvoker({required MemoryRegistry registry})
    : _registry = registry;

  final MemoryRegistry _registry;

  Future<Result> store(String key) =>
      _invoke(key, (memory, context) => memory.store(context));

  Future<Result> retrieve(String key) =>
      _invoke(key, (memory, context) => memory.retrieve(context));

  Future<Result> _invoke(
    String key,
    Future<Result> Function(Memory memory, MemoryContext context) operation,
  ) async {
    final memory = _registry.find(key);

    if (memory == null) {
      return Result.failure('Memory "$key" not found.');
    }

    final context = MemoryContext(key: key);

    try {
      return await operation(memory, context);
    } catch (e) {
      return Result.failure('Memory "$key" failed: $e');
    }
  }
}
