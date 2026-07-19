import 'package:pharos_ai_runtime/execution/execution_decision.dart';
import 'package:pharos_ai_runtime/execution/execution_strategy.dart';
import 'package:pharos_ai_runtime/planner/plan.dart';

/// The simplest ExecutionStrategy: selects every PlanStep of the given
/// Plan, in its original order. No filtering, no reordering, no
/// approvals, no retries.
class ImmediateExecutionStrategy implements ExecutionStrategy {
  const ImmediateExecutionStrategy();

  @override
  ExecutionDecision decide(Plan plan) {
    return ExecutionDecision(steps: List.of(plan.steps));
  }
}
