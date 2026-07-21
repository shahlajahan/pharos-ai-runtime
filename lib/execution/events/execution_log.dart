import 'package:pharos_ai_runtime/execution/events/execution_event.dart';

/// An append-only record of every ExecutionEvent emitted during one
/// Execution.
class ExecutionLog {
  ExecutionLog();

  final List<ExecutionEvent> _events = [];

  void record(ExecutionEvent event) => _events.add(event);

  List<ExecutionEvent> get events => List.unmodifiable(_events);
}
