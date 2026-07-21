import 'package:pharos_ai_runtime/workflow/models/workflow_step_status.dart';

/// One unit of work inside a Workflow. Immutable value object: no
/// execution logic, no service references, no side effects. A step may
/// depend on other steps by id — the Planner validates those
/// dependencies; WorkflowStep only ever carries them.
class WorkflowStep {
  const WorkflowStep({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.dependsOn,
    required this.metadata,
  });

  final String id;
  final String title;
  final String description;
  final WorkflowStepStatus status;

  /// The ids of WorkflowSteps that must complete before this one may
  /// run.
  final List<String> dependsOn;

  final Map<String, Object> metadata;
}
