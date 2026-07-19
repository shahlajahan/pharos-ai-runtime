import 'package:pharos_ai_runtime/runtime/plan/runtime_plan.dart';
import 'package:pharos_ai_runtime/workflow/workflow.dart';

/// Transforms a RuntimePlan into an executable Workflow — the bridge
/// between Planning and Execution. Performs no execution, no planning,
/// no tool invocation: exactly one responsibility, building the
/// Workflow.
abstract interface class WorkflowBuilder {
  Future<Workflow> build(RuntimePlan plan);
}
