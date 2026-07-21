import 'package:pharos_ai_runtime/agents/models/agent.dart';
import 'package:pharos_ai_runtime/agents/models/agent_id.dart';
import 'package:pharos_ai_runtime/agents/models/agent_status.dart';
import 'package:pharos_ai_runtime/agents/models/capability.dart';
import 'package:pharos_ai_runtime/agents/models/capability_set.dart';
import 'package:pharos_ai_runtime/agents/runtime/capability_matcher.dart';
import 'package:pharos_ai_runtime/tasks/models/task.dart';
import 'package:pharos_ai_runtime/tasks/models/task_dependency.dart';
import 'package:pharos_ai_runtime/tasks/models/task_priority.dart';
import 'package:pharos_ai_runtime/tasks/models/task_status.dart';
import 'package:pharos_ai_runtime/tasks/models/task_type.dart';
import 'package:test/test.dart';

Agent _agent(
  String id, {
  Set<Capability> capabilities = const {},
  AgentStatus status = AgentStatus.available,
  TaskPriority priority = TaskPriority.medium,
}) => Agent(
  id: AgentId(id),
  name: id,
  description: '',
  status: status,
  capabilities: CapabilitySet(capabilities),
  priority: priority,
  metadata: const {},
);

Task _task(List<String> requiredCapabilities) => Task(
  id: 'generate-images',
  title: 'Generate Images',
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
  test('match() scores an agent covering every required capability at 1.0', () {
    const matcher = CapabilityMatcher();
    final agent = _agent(
      'creative-agent',
      capabilities: {
        const Capability('image-generation'),
        const Capability('creative-design'),
      },
    );

    final candidates = matcher.match(
      _task(['image-generation', 'creative-design']),
      [agent],
    );

    expect(candidates, hasLength(1));
    expect(candidates.single.capabilityScore, 1.0);
  });

  test(
    'match() scores an agent covering half the required capabilities at 0.5',
    () {
      const matcher = CapabilityMatcher();
      final agent = _agent(
        'marketing-agent',
        capabilities: {const Capability('creative-design')},
      );

      final candidates = matcher.match(
        _task(['image-generation', 'creative-design']),
        [agent],
      );

      expect(candidates.single.capabilityScore, 0.5);
    },
  );

  test('match() excludes an agent with none of the required capabilities '
      '(missing capability)', () {
    const matcher = CapabilityMatcher();
    final agent = _agent(
      'legal-agent',
      capabilities: {const Capability('legal-review')},
    );

    final candidates = matcher.match(
      _task(['image-generation', 'creative-design']),
      [agent],
    );

    expect(candidates, isEmpty);
  });

  test('match() excludes an offline agent even if fully capable', () {
    const matcher = CapabilityMatcher();
    final agent = _agent(
      'creative-agent',
      capabilities: {const Capability('image-generation')},
      status: AgentStatus.offline,
    );

    final candidates = matcher.match(_task(['image-generation']), [agent]);

    expect(candidates, isEmpty);
  });

  test('match() excludes a disabled agent even if fully capable', () {
    const matcher = CapabilityMatcher();
    final agent = _agent(
      'creative-agent',
      capabilities: {const Capability('image-generation')},
      status: AgentStatus.disabled,
    );

    final candidates = matcher.match(_task(['image-generation']), [agent]);

    expect(candidates, isEmpty);
  });

  test('match() includes a busy agent as an eligible candidate', () {
    const matcher = CapabilityMatcher();
    final agent = _agent(
      'creative-agent',
      capabilities: {const Capability('image-generation')},
      status: AgentStatus.busy,
    );

    final candidates = matcher.match(_task(['image-generation']), [agent]);

    expect(candidates, hasLength(1));
  });

  test('match() returns multiple ranked candidates for the same task', () {
    const matcher = CapabilityMatcher();
    final creative = _agent(
      'creative-agent',
      capabilities: {
        const Capability('image-generation'),
        const Capability('creative-design'),
      },
    );
    final marketing = _agent(
      'marketing-agent',
      capabilities: {const Capability('creative-design')},
    );

    final candidates = matcher.match(
      _task(['image-generation', 'creative-design']),
      [creative, marketing],
    );

    expect(candidates, hasLength(2));
    expect(candidates.map((c) => c.agent.id.value).toSet(), {
      'creative-agent',
      'marketing-agent',
    });
  });

  test('match() treats a task with no required capabilities as fully '
      'covered by any eligible agent', () {
    const matcher = CapabilityMatcher();
    final agent = _agent('general-agent');

    final candidates = matcher.match(_task(const []), [agent]);

    expect(candidates.single.capabilityScore, 1.0);
  });
}
