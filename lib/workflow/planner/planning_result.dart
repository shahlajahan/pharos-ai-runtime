import 'package:pharos_ai_runtime/workflow/planner/workflow_instance.dart';
import 'package:pharos_ai_runtime/workflow/planner/workflow_plan.dart';

/// The outcome of one WorkflowPlanner.plan() call. If validation fails,
/// [success] is false and [workflow]/[plan] stay null — no
/// WorkflowInstance is ever returned for an invalid workflow.
class PlanningResult {
  const PlanningResult({
    required this.success,
    required this.workflow,
    required this.plan,
    required this.errors,
    required this.warnings,
  });

  final bool success;
  final WorkflowInstance? workflow;
  final WorkflowPlan? plan;
  final List<String> errors;
  final List<String> warnings;
}
