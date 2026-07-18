import 'package:pharos_ai_runtime/memory/conversation_memory.dart';
import 'package:pharos_ai_runtime/runtime/employee_runtime.dart';

/// Shared execution state for a single HQ.execute() call. Intentionally
/// minimal today; future HQ features (Planner, Workflow, Variables,
/// Artifacts, Tracing) will extend it.
class HQContext {
  HQContext({
    required this.goal,
    required this.employee,
    ConversationMemory? memory,
  }) : memory = memory ?? ConversationMemory();

  final String goal;
  final EmployeeRuntime employee;
  final ConversationMemory memory;
}
