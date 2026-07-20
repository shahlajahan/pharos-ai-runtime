import 'package:pharos_ai_runtime/knowledge/fact_type.dart';

/// A signal's known value, or unknown. Never fabricated: a signal stays
/// [unknown] until something in the Knowledge Graph deterministically
/// establishes it as true or false — existence of a fact is never
/// treated as proof of readiness.
enum SignalState { yes, no, unknown }

/// What the Runtime currently knows about one entity's operational
/// readiness — not just whether it exists, but whether it is reachable,
/// connected, or actively producing data. Immutable and deterministic:
/// OperationalStateBuilder is the only place a state is constructed.
class OperationalState {
  const OperationalState({
    required this.factId,
    required this.factType,
    required this.name,
    required this.signals,
  });

  final String factId;
  final FactType factType;
  final String name;

  /// Readiness signals for this entity (for example "analyticsConnected"
  /// -> [SignalState.no] for a Website with no connected analytics
  /// platform). Always includes "exists", which is always
  /// [SignalState.yes] — an OperationalState only ever exists for a fact
  /// the Knowledge Graph already knows about.
  final Map<String, SignalState> signals;
}
