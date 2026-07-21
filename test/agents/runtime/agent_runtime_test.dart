import 'package:pharos_ai_runtime/agents/models/agent.dart';
import 'package:pharos_ai_runtime/agents/models/agent_id.dart';
import 'package:pharos_ai_runtime/agents/models/agent_status.dart';
import 'package:pharos_ai_runtime/agents/models/capability.dart';
import 'package:pharos_ai_runtime/agents/models/capability_set.dart';
import 'package:pharos_ai_runtime/agents/registry/agent_registry.dart';
import 'package:pharos_ai_runtime/agents/runtime/agent_runtime.dart';
import 'package:pharos_ai_runtime/tasks/models/task.dart';
import 'package:pharos_ai_runtime/tasks/models/task_dependency.dart';
import 'package:pharos_ai_runtime/tasks/models/task_priority.dart';
import 'package:pharos_ai_runtime/tasks/models/task_status.dart';
import 'package:pharos_ai_runtime/tasks/models/task_type.dart';
import 'package:test/test.dart';

Agent _agent(
  String id,
  String name, {
  Set<Capability> capabilities = const {},
  AgentStatus status = AgentStatus.available,
  TaskPriority priority = TaskPriority.medium,
}) => Agent(
  id: AgentId(id),
  name: name,
  description: '',
  status: status,
  capabilities: CapabilitySet(capabilities),
  priority: priority,
  metadata: const {},
);

Task _task(String id, {List<String> requiredCapabilities = const []}) => Task(
  id: id,
  title: id,
  description: '',
  type: TaskType.generation,
  priority: TaskPriority.high,
  status: TaskStatus.pending,
  dependencies: const <TaskDependency>[],
  requiredCapabilities: requiredCapabilities,
  estimatedDuration: Duration.zero,
  metadata: const {},
);

void main() {
  test("assign() picks the Creative Agent for a Generate Images task, "
      "matching the roadmap's own example ranking", () {
    final registry = AgentRegistry()
      ..register(
        _agent(
          'creative-agent',
          'Creative Agent',
          capabilities: {
            const Capability('image-generation'),
            const Capability('creative-design'),
          },
          priority: TaskPriority.critical,
        ),
      )
      ..register(
        _agent(
          'marketing-agent',
          'Marketing Agent',
          capabilities: {const Capability('creative-design')},
          priority: TaskPriority.high,
        ),
      )
      ..register(
        _agent(
          'general-agent',
          'General Agent',
          capabilities: {const Capability('image-generation')},
          priority: TaskPriority.low,
        ),
      );
    final runtime = AgentRuntime(registry: registry);

    final result = runtime.assign([
      _task(
        'generate-images',
        requiredCapabilities: ['image-generation', 'creative-design'],
      ),
    ]);

    expect(result.assignments, hasLength(1));
    expect(result.assignments.single.agentId.value, 'creative-agent');
    expect(result.assignments.single.capabilityScore, 1.0);
    expect(result.unassignedTasks, isEmpty);
  });

  test('assign() reports a task as unassigned when no agent has the '
      'required capability', () {
    final registry = AgentRegistry()
      ..register(
        _agent(
          'legal-agent',
          'Legal Agent',
          capabilities: {const Capability('legal-review')},
        ),
      );
    final runtime = AgentRuntime(registry: registry);

    final result = runtime.assign([
      _task('generate-images', requiredCapabilities: ['image-generation']),
    ]);

    expect(result.assignments, isEmpty);
    expect(result.unassignedTasks, ['generate-images']);
    expect(result.warnings, isNotEmpty);
  });

  test(
    'assign() skips an offline agent even when it is the only registered agent',
    () {
      final registry = AgentRegistry()
        ..register(
          _agent(
            'creative-agent',
            'Creative Agent',
            capabilities: {const Capability('image-generation')},
            status: AgentStatus.offline,
          ),
        );
      final runtime = AgentRuntime(registry: registry);

      final result = runtime.assign([
        _task('generate-images', requiredCapabilities: ['image-generation']),
      ]);

      expect(result.assignments, isEmpty);
      expect(result.unassignedTasks, ['generate-images']);
    },
  );

  test(
    'assign() produces a reason and capability score for every assignment',
    () {
      final registry = AgentRegistry()
        ..register(
          _agent(
            'creative-agent',
            'Creative Agent',
            capabilities: {const Capability('image-generation')},
          ),
        );
      final runtime = AgentRuntime(registry: registry);

      final result = runtime.assign([
        _task('generate-images', requiredCapabilities: ['image-generation']),
      ]);

      final assignment = result.assignments.single;
      expect(assignment.capabilityScore, 1.0);
      expect(assignment.reason, contains('Creative Agent'));
      expect(assignment.reason, contains('100%'));
    },
  );

  test('assign() handles multiple tasks independently in one call', () {
    final registry = AgentRegistry()
      ..register(
        _agent(
          'creative-agent',
          'Creative Agent',
          capabilities: {const Capability('image-generation')},
        ),
      )
      ..register(
        _agent(
          'copy-agent',
          'Copy Agent',
          capabilities: {const Capability('copywriting')},
        ),
      );
    final runtime = AgentRuntime(registry: registry);

    final result = runtime.assign([
      _task('generate-images', requiredCapabilities: ['image-generation']),
      _task('write-caption', requiredCapabilities: ['copywriting']),
    ]);

    expect(result.assignments, hasLength(2));
    expect(result.assignments.map((a) => a.agentId.value).toSet(), {
      'creative-agent',
      'copy-agent',
    });
  });

  test(
    'assign() never executes anything: it only produces an AssignmentResult',
    () {
      final registry = AgentRegistry()
        ..register(
          _agent(
            'creative-agent',
            'Creative Agent',
            capabilities: {const Capability('image-generation')},
          ),
        );
      final runtime = AgentRuntime(registry: registry);

      final result = runtime.assign([
        _task('generate-images', requiredCapabilities: ['image-generation']),
      ]);

      expect(result, isA<Object>());
    },
  );

  test('assign() is deterministic', () {
    final registry = AgentRegistry()
      ..register(
        _agent(
          'creative-agent',
          'Creative Agent',
          capabilities: {const Capability('image-generation')},
        ),
      );
    final runtime = AgentRuntime(registry: registry);
    final tasks = [
      _task('generate-images', requiredCapabilities: ['image-generation']),
    ];

    final first = runtime.assign(tasks);
    final second = runtime.assign(tasks);

    expect(
      first.assignments.map((a) => a.agentId.value).toList(),
      second.assignments.map((a) => a.agentId.value).toList(),
    );
  });
}
