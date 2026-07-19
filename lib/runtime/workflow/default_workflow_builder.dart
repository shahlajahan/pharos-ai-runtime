import 'package:pharos_ai_runtime/runtime/plan/runtime_plan.dart';
import 'package:pharos_ai_runtime/runtime/workflow/minimal_workflow.dart';
import 'package:pharos_ai_runtime/runtime/workflow/workflow_builder.dart';
import 'package:pharos_ai_runtime/workflow/workflow.dart';

/// The first concrete WorkflowBuilder: deterministic, dependency-free
/// workflow construction that returns the simplest possible Workflow
/// implementation. No execution, no planning, no AI, no tools.
class DefaultWorkflowBuilder implements WorkflowBuilder {
  const DefaultWorkflowBuilder();

  @override
  Future<Workflow> build(RuntimePlan plan) async {
    return const MinimalWorkflow();
  }
}
