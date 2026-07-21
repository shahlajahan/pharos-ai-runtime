import 'package:pharos_ai_runtime/agents/models/agent.dart';
import 'package:pharos_ai_runtime/agents/models/agent_id.dart';
import 'package:pharos_ai_runtime/agents/models/agent_status.dart';
import 'package:pharos_ai_runtime/agents/models/capability.dart';
import 'package:pharos_ai_runtime/agents/models/capability_set.dart';
import 'package:pharos_ai_runtime/agents/registry/agent_registry.dart';
import 'package:pharos_ai_runtime/tasks/models/task_priority.dart';
import 'package:test/test.dart';

Agent _agent(String id, {AgentStatus status = AgentStatus.available}) => Agent(
  id: AgentId(id),
  name: id,
  description: '',
  status: status,
  capabilities: CapabilitySet({const Capability('image-generation')}),
  priority: TaskPriority.medium,
  metadata: const {},
);

void main() {
  test('register() adds an Agent, visible via list()', () {
    final registry = AgentRegistry();

    registry.register(_agent('creative-agent'));

    expect(registry.list().map((a) => a.id.value), ['creative-agent']);
  });

  test('register() throws ArgumentError for a duplicate id rather than '
      'silently overwriting it', () {
    final registry = AgentRegistry()..register(_agent('creative-agent'));

    expect(
      () => registry.register(_agent('creative-agent')),
      throwsArgumentError,
    );
    expect(registry.list(), hasLength(1));
  });

  test('remove() removes an agent by id', () {
    final registry = AgentRegistry()..register(_agent('creative-agent'));

    registry.remove(const AgentId('creative-agent'));

    expect(registry.list(), isEmpty);
  });

  test('remove() is a no-op for an id that was never registered', () {
    final registry = AgentRegistry();

    registry.remove(const AgentId('nonexistent'));

    expect(registry.list(), isEmpty);
  });

  test('find() returns the registered agent by id, or null', () {
    final registry = AgentRegistry()..register(_agent('creative-agent'));

    expect(
      registry.find(const AgentId('creative-agent'))?.id.value,
      'creative-agent',
    );
    expect(registry.find(const AgentId('nonexistent')), isNull);
  });

  test('list() returns every registered agent', () {
    final registry = AgentRegistry()
      ..register(_agent('creative-agent'))
      ..register(_agent('marketing-agent'));

    expect(registry.list(), hasLength(2));
  });
}
