import 'package:pharos_ai_runtime/runtime/plan/runtime_plan.dart';
import 'package:pharos_ai_runtime/runtime/planning/planning_request.dart';
import 'package:pharos_ai_runtime/runtime/planning/planning_result.dart';
import 'package:pharos_ai_runtime/runtime/planning/runtime_planner.dart';

/// The first concrete RuntimePlanner: deterministic, dependency-free
/// planning that transforms a RuntimeIntent directly into a RuntimePlan
/// carrying the same id and title. No AI, no LLM, no prompt, no tool.
class DefaultRuntimePlanner implements RuntimePlanner {
  const DefaultRuntimePlanner();

  @override
  Future<PlanningResult> plan(PlanningRequest request) async {
    return PlanningResult(
      plan: RuntimePlan(id: request.intent.id, title: request.intent.title),
    );
  }
}
