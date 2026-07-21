import 'package:pharos_ai_runtime/agents/models/agent.dart';
import 'package:pharos_ai_runtime/agents/models/agent_id.dart';
import 'package:pharos_ai_runtime/agents/models/agent_status.dart';
import 'package:pharos_ai_runtime/agents/models/capability_set.dart';
import 'package:pharos_ai_runtime/agents/runtime/agent_selector.dart';
import 'package:pharos_ai_runtime/tasks/models/task_priority.dart';
import 'package:test/test.dart';

Agent _agent(
  String id, {
  AgentStatus status = AgentStatus.available,
  TaskPriority priority = TaskPriority.medium,
}) => Agent(
  id: AgentId(id),
  name: id,
  description: '',
  status: status,
  capabilities: const CapabilitySet({}),
  priority: priority,
  metadata: const {},
);

({Agent agent, double capabilityScore}) _candidate(Agent agent, double score) =>
    (agent: agent, capabilityScore: score);

void main() {
  test('select() returns null when there are no candidates', () {
    const selector = AgentSelector();

    expect(selector.select(const []), isNull);
  });

  test('select() prefers the highest capability score', () {
    const selector = AgentSelector();
    final low = _agent('low-score');
    final high = _agent('high-score');

    final chosen = selector.select([
      _candidate(low, 0.5),
      _candidate(high, 1.0),
    ]);

    expect(chosen!.id.value, 'high-score');
  });

  test('select() breaks a capability-score tie by highest priority', () {
    const selector = AgentSelector();
    final lowPriority = _agent('low-priority', priority: TaskPriority.low);
    final highPriority = _agent(
      'high-priority',
      priority: TaskPriority.critical,
    );

    final chosen = selector.select([
      _candidate(lowPriority, 0.8),
      _candidate(highPriority, 0.8),
    ]);

    expect(chosen!.id.value, 'high-priority');
  });

  test('select() breaks a score-and-priority tie by lowest workload '
      '(available before busy)', () {
    const selector = AgentSelector();
    final busy = _agent('busy-agent', status: AgentStatus.busy);
    final available = _agent('available-agent', status: AgentStatus.available);

    final chosen = selector.select([
      _candidate(busy, 0.8),
      _candidate(available, 0.8),
    ]);

    expect(chosen!.id.value, 'available-agent');
  });

  test('select() is never random: identical input always selects the '
      'same agent', () {
    const selector = AgentSelector();
    final a = _agent('agent-a');
    final b = _agent('agent-b');
    final candidates = [_candidate(a, 0.5), _candidate(b, 0.5)];

    final first = selector.select(candidates);
    final second = selector.select(candidates);

    expect(first!.id.value, second!.id.value);
  });
}
