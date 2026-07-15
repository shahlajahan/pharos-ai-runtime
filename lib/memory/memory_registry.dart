import 'package:pharos_ai_runtime/memory/memory.dart';

class MemoryRegistry {
  const MemoryRegistry({Map<String, Memory> memories = const {}})
    : _memories = memories;

  final Map<String, Memory> _memories;

  Memory? find(String id) => _memories[id];
}
