import 'package:pharos_ai_runtime/decision/decision_type.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_priority.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_step.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_type.dart';

/// A reusable workflow template — not a running Workflow instance.
/// Immutable, no runtime state, no execution logic: a WorkflowPlanner
/// turns a WorkflowDefinition (found via the WorkflowRegistry) into a
/// concrete Workflow.
class WorkflowDefinition {
  const WorkflowDefinition({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.supportedDecisionTypes,
    required this.defaultPriority,
    required this.steps,
    required this.metadata,
  });

  final String id;
  final WorkflowType type;
  final String title;
  final String description;

  /// The DecisionTypes this definition can be matched against (for
  /// example [DecisionType.launch] for `launch_campaign`).
  final List<DecisionType> supportedDecisionTypes;

  final WorkflowPriority defaultPriority;
  final List<WorkflowStep> steps;
  final Map<String, Object> metadata;
}
