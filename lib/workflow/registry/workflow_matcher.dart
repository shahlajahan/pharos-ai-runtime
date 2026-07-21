import 'package:pharos_ai_runtime/decision/decision.dart';
import 'package:pharos_ai_runtime/workflow/registry/workflow_definition.dart';
import 'package:pharos_ai_runtime/workflow/registry/workflow_registry.dart';

/// Maps a company Decision to the WorkflowDefinition that should handle
/// it, via the WorkflowRegistry — so a WorkflowPlanner never has to
/// hardcode which workflow a decision maps to. Never creates a Workflow
/// itself; it only ever selects the correct definition.
class WorkflowMatcher {
  const WorkflowMatcher(this._registry);

  final WorkflowRegistry _registry;

  WorkflowDefinition? match(Decision decision) =>
      _registry.findByDecision(decision);
}
