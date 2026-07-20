import 'package:pharos_ai_runtime/company/department.dart';
import 'package:pharos_ai_runtime/company/department_facts.dart';
import 'package:pharos_ai_runtime/knowledge/knowledge_graph.dart';
import 'package:pharos_ai_runtime/operations/decision_gate.dart';
import 'package:pharos_ai_runtime/operations/operational_state.dart';
import 'package:pharos_ai_runtime/operations/operational_state_builder.dart';
import 'package:pharos_ai_runtime/operations/state_completeness.dart';

/// One entity whose operational evidence is insufficient for an
/// action-level recommendation, and why — surfaced so the Runtime can
/// steer the LLM toward recommending better observability instead.
class BlockedRecommendation {
  const BlockedRecommendation({
    required this.state,
    required this.missingSignals,
    required this.confidence,
  });

  final OperationalState state;
  final List<String> missingSignals;
  final String confidence;
}

/// One department's operational readiness: which of its known facts are
/// backed by enough evidence to support an action-level recommendation,
/// which are not (and why), and an aggregate observability score. Built
/// once from DepartmentFacts and the Knowledge Graph; never mutated,
/// never touches the LLM.
class OperationalSnapshot {
  const OperationalSnapshot({
    required this.department,
    required this.states,
    required this.allowed,
    required this.blocked,
    required this.observabilityScore,
    required this.missingOperationalData,
  });

  factory OperationalSnapshot.build({
    required DepartmentFacts departmentFacts,
    required KnowledgeGraph graph,
    OperationalStateBuilder stateBuilder = const OperationalStateBuilder(),
    DecisionGate decisionGate = const DecisionGate(),
  }) {
    final states = [
      for (final fact in departmentFacts.facts) stateBuilder.build(fact, graph),
    ];

    final allowed = <OperationalState>[];
    final blocked = <BlockedRecommendation>[];
    final missingOperationalData = <String>{};

    for (final state in states) {
      final result = decisionGate.evaluate(state);

      if (result.allowed) {
        allowed.add(state);
      } else {
        blocked.add(
          BlockedRecommendation(
            state: state,
            missingSignals: result.missingSignals,
            confidence: result.confidence,
          ),
        );
        missingOperationalData.addAll(result.missingSignals);
      }
    }

    const completeness = StateCompleteness();
    final observabilityScore = states.isEmpty
        ? 0.0
        : states.map(completeness.calculate).reduce((a, b) => a + b) /
              states.length;

    return OperationalSnapshot(
      department: departmentFacts.department,
      states: states,
      allowed: allowed,
      blocked: blocked,
      observabilityScore: observabilityScore,
      missingOperationalData: missingOperationalData.toList(),
    );
  }

  final Department department;
  final List<OperationalState> states;

  /// States with enough evidence to support an action-level
  /// recommendation.
  final List<OperationalState> allowed;

  /// States without enough evidence, and why — the LLM must recommend
  /// improving observability for these instead of taking action.
  final List<BlockedRecommendation> blocked;

  /// The average [StateCompleteness] across every state in this
  /// department, 0.0 (nothing known) to 1.0 (everything known).
  final double observabilityScore;

  /// Every signal name still unknown across every blocked state in this
  /// department, deduplicated. Never fabricated: always reported, never
  /// guessed.
  final List<String> missingOperationalData;
}
