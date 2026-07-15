import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/memory/memory_context.dart';

abstract class Memory {
  Future<Result> store(MemoryContext context);

  Future<Result> retrieve(MemoryContext context);
}
