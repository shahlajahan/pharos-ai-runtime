import 'package:pharos_ai_runtime/execution/execution_decision.dart';
import 'package:pharos_ai_runtime/workflow/workflow_result.dart';

/// Executes an ExecutionDecision. Workflow owns orchestration only: it
/// never plans, never decides execution policy, and never talks to the
/// LLM directly — it delegates each selected PlanStep's execution to the
/// Employee assigned to that step, via HQ.
abstract class Workflow {
  Future<WorkflowResult> execute(ExecutionDecision decision);
}
