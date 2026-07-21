import 'package:pharos_ai_runtime/agents/models/agent_id.dart';

/// One Task's assignment to an Agent: which task, which agent, how well
/// the agent's capabilities matched, and why it was chosen. Immutable;
/// produced only by the Agent Runtime, never mutated afterward.
class TaskAssignment {
  const TaskAssignment({
    required this.taskId,
    required this.agentId,
    required this.capabilityScore,
    required this.reason,
  });

  final String taskId;
  final AgentId agentId;
  final double capabilityScore;
  final String reason;
}
