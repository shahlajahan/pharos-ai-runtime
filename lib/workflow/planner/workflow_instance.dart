import 'package:pharos_ai_runtime/workflow/models/workflow_context.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_status.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_step.dart';

/// One planned execution of a WorkflowDefinition. Every planning
/// request creates a new WorkflowInstance. Immutable value object: no
/// execution logic.
class WorkflowInstance {
  const WorkflowInstance({
    required this.id,
    required this.definitionId,
    required this.status,
    required this.context,
    required this.steps,
    required this.createdAt,
    required this.plannedAt,
  });

  final String id;

  /// The [WorkflowDefinition.id] this instance was planned from.
  final String definitionId;

  final WorkflowStatus status;
  final WorkflowContext context;
  final List<WorkflowStep> steps;
  final DateTime createdAt;
  final DateTime plannedAt;
}
