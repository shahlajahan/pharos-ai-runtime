import 'package:pharos_ai_runtime/agents/models/agent.dart';
import 'package:pharos_ai_runtime/agents/models/agent_status.dart';
import 'package:pharos_ai_runtime/agents/models/capability.dart';
import 'package:pharos_ai_runtime/agents/models/capability_set.dart';
import 'package:pharos_ai_runtime/tasks/models/task.dart';

/// Matches a Task's requiredCapabilities against every candidate Agent,
/// scoring each eligible one by capability coverage. An agent that is
/// offline or disabled is never eligible; an agent with none of the
/// required capabilities is not a candidate either. Deterministic: no
/// AI, no HTTP, no filesystem.
class CapabilityMatcher {
  const CapabilityMatcher();

  List<({Agent agent, double capabilityScore})> match(
    Task task,
    List<Agent> agents,
  ) {
    final required = CapabilitySet({
      for (final id in task.requiredCapabilities) Capability(id),
    });

    return [
      for (final agent in agents)
        if (_isEligible(agent))
          if (agent.capabilities.score(required) > 0)
            (agent: agent, capabilityScore: agent.capabilities.score(required)),
    ];
  }

  bool _isEligible(Agent agent) =>
      agent.status == AgentStatus.available || agent.status == AgentStatus.busy;
}
