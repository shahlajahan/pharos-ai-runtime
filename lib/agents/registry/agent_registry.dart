import 'package:pharos_ai_runtime/agents/models/agent.dart';
import 'package:pharos_ai_runtime/agents/models/agent_id.dart';

/// Stores every registered Agent. Contains agents only — no execution,
/// no knowledge of tasks, tools, or capability matching. Mutable only
/// via [register] and [remove].
class AgentRegistry {
  AgentRegistry();

  final Map<String, Agent> _agents = {};

  /// Registers [agent]. Throws [ArgumentError] if an agent with the
  /// same id is already registered — a duplicate is never silently
  /// overwritten.
  void register(Agent agent) {
    if (_agents.containsKey(agent.id.value)) {
      throw ArgumentError.value(
        agent.id.value,
        'agent.id',
        'An Agent with this id is already registered.',
      );
    }

    _agents[agent.id.value] = agent;
  }

  void remove(AgentId id) {
    _agents.remove(id.value);
  }

  Agent? find(AgentId id) => _agents[id.value];

  List<Agent> list() => _agents.values.toList();
}
