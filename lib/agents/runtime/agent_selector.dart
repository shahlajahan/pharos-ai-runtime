import 'package:pharos_ai_runtime/agents/models/agent.dart';
import 'package:pharos_ai_runtime/agents/models/agent_status.dart';

/// Chooses the single best Agent from a set of scored candidates.
/// Deterministic, never random: highest capability score first, then
/// highest priority, then lowest workload (an available agent is
/// preferred over a busy one).
class AgentSelector {
  const AgentSelector();

  Agent? select(List<({Agent agent, double capabilityScore})> candidates) {
    if (candidates.isEmpty) {
      return null;
    }

    final sorted = [...candidates]
      ..sort((a, b) {
        final byScore = b.capabilityScore.compareTo(a.capabilityScore);
        if (byScore != 0) {
          return byScore;
        }

        final byPriority = a.agent.priority.index.compareTo(
          b.agent.priority.index,
        );
        if (byPriority != 0) {
          return byPriority;
        }

        return _workload(a.agent.status).compareTo(_workload(b.agent.status));
      });

    return sorted.first.agent;
  }

  /// Lower is "less busy" and therefore preferred. Agents this far into
  /// selection are always available or busy (CapabilityMatcher already
  /// excludes offline/disabled ones), but the full ordering is kept
  /// total and deterministic regardless of how candidates were built.
  int _workload(AgentStatus status) => switch (status) {
    AgentStatus.available => 0,
    AgentStatus.busy => 1,
    AgentStatus.offline => 2,
    AgentStatus.disabled => 3,
  };
}
