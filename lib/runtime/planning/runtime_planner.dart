import 'package:pharos_ai_runtime/runtime/planning/planning_request.dart';
import 'package:pharos_ai_runtime/runtime/planning/planning_result.dart';

/// Transforms a PlanningRequest (carrying a RuntimeIntent) into a
/// PlanningResult. Runtime's own Planning abstraction — nothing else, no
/// helper methods.
abstract interface class RuntimePlanner {
  Future<PlanningResult> plan(PlanningRequest request);
}
