import 'package:pharos_ai_runtime/execution/execution_decision.dart';
import 'package:pharos_ai_runtime/runtime/engine/runtime_engine.dart';
import 'package:pharos_ai_runtime/runtime/intent/runtime_intent.dart';
import 'package:pharos_ai_runtime/runtime/plan/runtime_plan.dart';
import 'package:pharos_ai_runtime/runtime/planning/planning_request.dart';
import 'package:pharos_ai_runtime/runtime/planning/runtime_planner.dart';
import 'package:pharos_ai_runtime/runtime/workflow/workflow_builder.dart';
import 'package:pharos_ai_runtime/workflow/workflow_result.dart';

/// The first concrete RuntimeEngine: composes the existing Runtime
/// contracts — RuntimePlanner, WorkflowBuilder, and the resulting
/// Workflow — into one orchestration entry point. Composition only: no
/// planning logic, no workflow construction logic, no execution logic
/// beyond invoking these collaborators.
class DefaultRuntimeEngine implements RuntimeEngine {
  const DefaultRuntimeEngine({
    required this.planner,
    required this.workflowBuilder,
    required this.executionDecision,
  });

  final RuntimePlanner planner;
  final WorkflowBuilder workflowBuilder;
  final ExecutionDecision executionDecision;

  @override
  Future<WorkflowResult> execute(RuntimeIntent intent) async {
    final planningResult = await planner.plan(PlanningRequest(intent: intent));

    final workflow = await workflowBuilder.build(
      planningResult.plan as RuntimePlan,
    );

    return workflow.execute(executionDecision);
  }
}
