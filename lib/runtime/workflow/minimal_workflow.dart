import 'package:pharos_ai_runtime/execution/execution_decision.dart';
import 'package:pharos_ai_runtime/workflow/workflow.dart';
import 'package:pharos_ai_runtime/workflow/workflow_result.dart';

/// The simplest possible Workflow: executes nothing itself and simply
/// returns an empty WorkflowResult. No additional logic.
class MinimalWorkflow implements Workflow {
  const MinimalWorkflow();

  @override
  Future<WorkflowResult> execute(ExecutionDecision decision) async {
    return const WorkflowResult(stepResults: []);
  }
}
