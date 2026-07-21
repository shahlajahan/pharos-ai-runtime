import 'package:pharos_ai_runtime/decision/decision.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_type.dart';
import 'package:pharos_ai_runtime/workflow/registry/workflow_definition.dart';

/// The catalog of executable business workflows. Contains definitions
/// only: it never executes a workflow, and knows nothing about agents,
/// tools, AI, or external APIs. Mutable only via [register] and
/// [unregister] — read-only once execution begins.
class WorkflowRegistry {
  WorkflowRegistry();

  final Map<String, WorkflowDefinition> _definitions = {};

  /// Registers [definition]. Throws [ArgumentError] if a definition
  /// with the same id is already registered — a duplicate is never
  /// silently overwritten.
  void register(WorkflowDefinition definition) {
    if (_definitions.containsKey(definition.id)) {
      throw ArgumentError.value(
        definition.id,
        'definition.id',
        'A WorkflowDefinition with this id is already registered.',
      );
    }

    _definitions[definition.id] = definition;
  }

  void unregister(String id) {
    _definitions.remove(id);
  }

  List<WorkflowDefinition> findByType(WorkflowType type) => [
    for (final definition in _definitions.values)
      if (definition.type == type) definition,
  ];

  /// The first registered definition (in registration order) whose
  /// [WorkflowDefinition.supportedDecisionTypes] includes
  /// `decision.type`, or null if none matches.
  WorkflowDefinition? findByDecision(Decision decision) {
    for (final definition in _definitions.values) {
      if (definition.supportedDecisionTypes.contains(decision.type)) {
        return definition;
      }
    }

    return null;
  }

  List<WorkflowDefinition> all() => _definitions.values.toList();
}
