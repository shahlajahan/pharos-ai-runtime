import 'package:pharos_ai_runtime/workflow/models/workflow_context.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_priority.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_status.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_step.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_type.dart';

/// One complete business process, converted from a company Decision by
/// a WorkflowPlanner. Immutable value object: no execution logic, no
/// API knowledge, no service references. Nothing here executes — this
/// milestone only introduces the domain object a future execution layer
/// will run.
class Workflow {
  const Workflow({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.context,
    required this.steps,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final WorkflowType type;
  final String title;
  final String description;
  final WorkflowPriority priority;
  final WorkflowStatus status;
  final WorkflowContext context;
  final List<WorkflowStep> steps;
  final DateTime createdAt;
  final DateTime updatedAt;
}
