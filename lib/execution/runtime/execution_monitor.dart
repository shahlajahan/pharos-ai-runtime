import 'package:pharos_ai_runtime/execution/events/execution_event.dart';
import 'package:pharos_ai_runtime/execution/events/execution_log.dart';

/// Observes one Execution Engine run: emits events to an ExecutionLog,
/// and accumulates the failures, warnings, and metrics an
/// ExecutionResult reports at the end.
class ExecutionMonitor {
  ExecutionMonitor({ExecutionLog? log}) : log = log ?? ExecutionLog();

  final ExecutionLog log;
  final List<String> _failures = [];
  final List<String> _warnings = [];
  final Map<String, Object> _metrics = {};

  void recordEvent(
    ExecutionEventType type, {
    String? taskId,
    String message = '',
  }) {
    log.record(
      ExecutionEvent(
        type: type,
        timestamp: DateTime.now(),
        taskId: taskId,
        message: message,
      ),
    );
  }

  void captureFailure(String taskId, String reason) =>
      _failures.add('Task "$taskId" failed: $reason');

  void recordWarning(String message) => _warnings.add(message);

  void recordMetric(String key, Object value) => _metrics[key] = value;

  List<String> get failures => List.unmodifiable(_failures);
  List<String> get warnings => List.unmodifiable(_warnings);
  Map<String, Object> get metrics => Map.unmodifiable(_metrics);
}
