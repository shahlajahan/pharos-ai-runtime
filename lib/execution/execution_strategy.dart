import 'package:pharos_ai_runtime/execution/execution_decision.dart';
import 'package:pharos_ai_runtime/planner/plan.dart';

/// Decides which PlanSteps of a Plan should be selected for execution, and
/// in what order. An ExecutionStrategy never executes anything itself — it
/// only produces an ExecutionDecision describing the selection.
abstract class ExecutionStrategy {
  ExecutionDecision decide(Plan plan);
}
