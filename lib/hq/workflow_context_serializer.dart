import 'package:pharos_ai_runtime/workflow/workflow_context.dart';

/// Deterministically serializes a WorkflowContext's previousSteps into the
/// "Previous Workflow Results" summary HQ prepends to the current goal.
/// Pure serialization: no AI summarization, no truncation, no
/// interpretation — the same WorkflowContext always serializes to the
/// same String.
class WorkflowContextSerializer {
  const WorkflowContextSerializer();

  String serialize(WorkflowContext context) {
    final buffer = StringBuffer('Previous Workflow Results\n');

    for (var i = 0; i < context.previousSteps.length; i++) {
      final stepResult = context.previousSteps[i];

      buffer
        ..write('\n${i + 1}.\n')
        ..write('\nEmployee:\n${stepResult.step.assignedEmployee}\n')
        ..write('\nGoal:\n${stepResult.step.description}\n')
        ..write('\nResult:\n${stepResult.result.message}\n');
    }

    return buffer.toString();
  }
}
