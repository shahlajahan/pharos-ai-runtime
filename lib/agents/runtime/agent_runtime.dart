import 'package:pharos_ai_runtime/agents/models/agent.dart';
import 'package:pharos_ai_runtime/agents/models/task_assignment.dart';
import 'package:pharos_ai_runtime/agents/registry/agent_registry.dart';
import 'package:pharos_ai_runtime/agents/runtime/agent_selector.dart';
import 'package:pharos_ai_runtime/agents/runtime/assignment_result.dart';
import 'package:pharos_ai_runtime/agents/runtime/capability_matcher.dart';
import 'package:pharos_ai_runtime/tasks/models/task.dart';

/// Selects the most appropriate Agent for each executable Task: agent
/// discovery, capability matching, and assignment only. Never executes
/// a task — execution belongs to a future execution engine. Knows
/// tasks, capabilities, agents, and agent status only; never LLMs,
/// HTTP, APIs, the filesystem, CRM, finance, or tool implementations.
class AgentRuntime {
  const AgentRuntime({
    required this.registry,
    this.matcher = const CapabilityMatcher(),
    this.selector = const AgentSelector(),
  });

  final AgentRegistry registry;
  final CapabilityMatcher matcher;
  final AgentSelector selector;

  AssignmentResult assign(List<Task> tasks) {
    final agents = registry.list();
    final assignments = <TaskAssignment>[];
    final unassignedTasks = <String>[];
    final warnings = <String>[];

    for (final task in tasks) {
      final candidates = matcher.match(task, agents);

      if (candidates.isEmpty) {
        unassignedTasks.add(task.id);
        warnings.add(
          'No eligible agent found for task "${task.id}" (requires: '
          '${task.requiredCapabilities.isEmpty ? 'none' : task.requiredCapabilities.join(', ')}).',
        );
        continue;
      }

      final chosen = selector.select(candidates)!;
      final chosenScore = candidates
          .firstWhere((candidate) => candidate.agent.id == chosen.id)
          .capabilityScore;

      assignments.add(
        TaskAssignment(
          taskId: task.id,
          agentId: chosen.id,
          capabilityScore: chosenScore,
          reason: _reasonFor(chosen, chosenScore),
        ),
      );
    }

    return AssignmentResult(
      assignments: assignments,
      unassignedTasks: unassignedTasks,
      warnings: warnings,
      errors: const [],
    );
  }

  String _reasonFor(Agent agent, double score) =>
      '${agent.name} matched ${(score * 100).round()}% of required '
      'capabilities at ${agent.priority.name} priority.';
}
