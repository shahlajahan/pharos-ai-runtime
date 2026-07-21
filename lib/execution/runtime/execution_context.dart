import 'package:pharos_ai_runtime/agents/models/task_assignment.dart';
import 'package:pharos_ai_runtime/company/company_context.dart';
import 'package:pharos_ai_runtime/tasks/models/task.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow.dart';

/// Everything an Execution Engine run needs, injected up front. The
/// Execution Engine never queries HQ directly — [companyContext] is how
/// company knowledge reaches it instead.
class ExecutionContext {
  const ExecutionContext({
    required this.workflow,
    required this.tasks,
    required this.assignments,
    required this.companyContext,
    required this.metadata,
  });

  final Workflow workflow;
  final List<Task> tasks;

  /// Pre-computed assignments carried through from the Agent Runtime,
  /// for reference and auditing. The Engine still asks the Agent
  /// Runtime for a fresh assignment each round, since which tasks are
  /// executable is only known once execution is under way.
  final List<TaskAssignment> assignments;

  final CompanyContext companyContext;
  final Map<String, Object> metadata;
}
