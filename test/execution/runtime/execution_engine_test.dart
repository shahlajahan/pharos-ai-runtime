import 'package:pharos_ai_runtime/agents/models/agent.dart';
import 'package:pharos_ai_runtime/agents/models/agent_id.dart';
import 'package:pharos_ai_runtime/agents/models/agent_status.dart';
import 'package:pharos_ai_runtime/agents/models/capability.dart';
import 'package:pharos_ai_runtime/agents/models/capability_set.dart';
import 'package:pharos_ai_runtime/agents/registry/agent_registry.dart';
import 'package:pharos_ai_runtime/agents/runtime/agent_runtime.dart';
import 'package:pharos_ai_runtime/company/company_context.dart';
import 'package:pharos_ai_runtime/execution/models/execution_status.dart';
import 'package:pharos_ai_runtime/execution/runtime/execution_context.dart';
import 'package:pharos_ai_runtime/execution/runtime/execution_engine.dart';
import 'package:pharos_ai_runtime/tasks/models/task.dart';
import 'package:pharos_ai_runtime/tasks/models/task_dependency.dart';
import 'package:pharos_ai_runtime/tasks/models/task_priority.dart';
import 'package:pharos_ai_runtime/tasks/models/task_status.dart';
import 'package:pharos_ai_runtime/tasks/models/task_type.dart';
import 'package:pharos_ai_runtime/tools/models/tool.dart';
import 'package:pharos_ai_runtime/tools/models/tool_capability.dart';
import 'package:pharos_ai_runtime/tools/models/tool_id.dart';
import 'package:pharos_ai_runtime/tools/models/tool_status.dart';
import 'package:pharos_ai_runtime/tools/registry/tool_registry.dart';
import 'package:pharos_ai_runtime/tools/runtime/tool_runtime.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_context.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_priority.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_status.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_type.dart';
import 'package:test/test.dart';

Task _task(
  String id, {
  List<String> dependsOn = const [],
  List<String> requiredCapabilities = const ['generation'],
}) => Task(
  id: id,
  title: id,
  description: '',
  type: TaskType.generation,
  priority: TaskPriority.medium,
  status: TaskStatus.pending,
  dependencies: [
    for (final dependency in dependsOn) TaskDependency(dependency),
  ],
  requiredCapabilities: requiredCapabilities,
  estimatedDuration: const Duration(minutes: 1),
  metadata: const {},
);

Agent _agent(String id, {AgentStatus status = AgentStatus.available}) => Agent(
  id: AgentId(id),
  name: id,
  description: '',
  status: status,
  capabilities: CapabilitySet({const Capability('generation')}),
  priority: TaskPriority.medium,
  metadata: const {},
);

Tool _tool(
  String id, {
  ToolStatus status = ToolStatus.available,
  List<String> supportedOperations = const ['generation'],
}) => Tool(
  id: ToolId(id),
  name: id,
  description: '',
  status: status,
  capabilities: {const ToolCapability('generation')},
  supportedOperations: supportedOperations,
  metadata: const {},
);

Workflow _workflow() => Workflow(
  id: 'workflow-1',
  type: WorkflowType.launchCampaign,
  title: 'Launch Campaign',
  description: '',
  priority: WorkflowPriority.medium,
  status: WorkflowStatus.running,
  context: const WorkflowContext(company: {}, market: {}, finance: {}),
  steps: const [],
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

const _companyContext = CompanyContext(
  company: [],
  knowledge: [],
  products: [],
  assets: [],
  services: [],
  websites: [],
  social: [],
  analytics: [],
);

ExecutionContext _context(List<Task> tasks) => ExecutionContext(
  workflow: _workflow(),
  tasks: tasks,
  assignments: const [],
  companyContext: _companyContext,
  metadata: const {},
);

ExecutionEngine _engine({
  List<Agent> agents = const [],
  List<Tool> tools = const [],
  int maxRetries = 1,
}) {
  final agentRegistry = AgentRegistry();
  for (final agent in agents) {
    agentRegistry.register(agent);
  }
  final toolRegistry = ToolRegistry();
  for (final tool in tools) {
    toolRegistry.register(tool);
  }
  return ExecutionEngine(
    agentRuntime: AgentRuntime(registry: agentRegistry),
    toolRuntime: ToolRuntime(registry: toolRegistry),
    maxRetries: maxRetries,
  );
}

void main() {
  test('simple execution: a single task is assigned, invoked, and '
      'completed', () {
    final engine = _engine(agents: [_agent('a1')], tools: [_tool('t1')]);

    final outcome = engine.run(_context([_task('task-1')]));

    expect(outcome.result.success, isTrue);
    expect(outcome.result.completedTasks, ['task-1']);
    expect(outcome.execution.status, ExecutionStatus.completed);
    expect(outcome.execution.steps, hasLength(1));
    expect(outcome.execution.steps.first.assignedAgent?.value, 'a1');
  });

  test('parallel execution: independent tasks are both completed in one '
      'run', () {
    final engine = _engine(agents: [_agent('a1')], tools: [_tool('t1')]);

    final outcome = engine.run(_context([_task('task-1'), _task('task-2')]));

    expect(outcome.result.success, isTrue);
    expect(outcome.result.completedTasks.toSet(), {'task-1', 'task-2'});
  });

  test('dependency ordering: a dependent task completes only after its '
      'dependency', () {
    final engine = _engine(agents: [_agent('a1')], tools: [_tool('t1')]);

    final outcome = engine.run(
      _context([
        _task('task-1'),
        _task('task-2', dependsOn: ['task-1']),
      ]),
    );

    expect(outcome.result.success, isTrue);
    final stepIds = outcome.execution.steps.map((s) => s.taskId).toList();
    expect(stepIds.indexOf('task-1'), lessThan(stepIds.indexOf('task-2')));
  });

  test('dependency ordering: a task blocked on a dependency that will '
      'never complete is reported as a deadlock failure', () {
    final engine = _engine(agents: [_agent('a1')], tools: [_tool('t1')]);

    final outcome = engine.run(
      _context([
        _task('task-1', dependsOn: ['missing-task']),
      ]),
    );

    expect(outcome.result.success, isFalse);
    expect(outcome.result.failedTasks, contains('task-1'));
    expect(outcome.execution.status, ExecutionStatus.failed);
  });

  test('agent failure: a task with no eligible agent is reported as '
      'failed', () {
    final engine = _engine(agents: const [], tools: [_tool('t1')]);

    final outcome = engine.run(_context([_task('task-1')]));

    expect(outcome.result.success, isFalse);
    expect(outcome.result.failedTasks, ['task-1']);
    expect(outcome.result.errors, isNotEmpty);
  });

  test('tool failure: a task with no matching tool fails after exhausting '
      'retries', () {
    final engine = _engine(
      agents: [_agent('a1')],
      tools: const [],
      maxRetries: 1,
    );

    final outcome = engine.run(_context([_task('task-1')]));

    expect(outcome.result.success, isFalse);
    expect(outcome.result.failedTasks, ['task-1']);
    expect(outcome.execution.steps.single.result?.success, isFalse);
  });

  test('retry: a failing tool invocation is retried up to maxRetries '
      'times before the task is reported as failed', () {
    final engine = _engine(
      agents: [_agent('a1')],
      tools: [
        _tool('t1', supportedOperations: const ['other-operation']),
      ],
      maxRetries: 2,
    );

    final outcome = engine.run(_context([_task('task-1')]));

    expect(outcome.result.success, isFalse);
    expect(
      outcome.result.warnings.where((w) => w.contains('retrying')),
      hasLength(2),
    );
  });

  test('pause: execution stops before starting a new round and reports '
      'paused, keeping already-completed work', () {
    final engine = _engine(agents: [_agent('a1')], tools: [_tool('t1')]);
    var calls = 0;

    final outcome = engine.run(
      _context([
        _task('task-1'),
        _task('task-2', dependsOn: ['task-1']),
      ]),
      controlSignal: () {
        calls++;
        return calls > 1 ? ExecutionStatus.paused : null;
      },
    );

    expect(outcome.execution.status, ExecutionStatus.paused);
    expect(outcome.result.completedTasks, ['task-1']);
    expect(outcome.result.failedTasks, isEmpty);
  });

  test('cancel: execution stops immediately and marks remaining tasks '
      'cancelled', () {
    final engine = _engine(agents: [_agent('a1')], tools: [_tool('t1')]);

    final outcome = engine.run(
      _context([_task('task-1')]),
      controlSignal: () => ExecutionStatus.cancelled,
    );

    expect(outcome.execution.status, ExecutionStatus.cancelled);
    expect(outcome.result.success, isFalse);
    expect(outcome.result.failedTasks, ['task-1']);
    expect(
      outcome.result.errors,
      contains('Execution was cancelled before completion.'),
    );
  });

  test('is deterministic for the same inputs', () {
    final engine = _engine(agents: [_agent('a1')], tools: [_tool('t1')]);

    final first = engine.run(_context([_task('task-1')]));
    final second = engine.run(_context([_task('task-1')]));

    expect(first.result.success, second.result.success);
    expect(first.result.completedTasks, second.result.completedTasks);
  });
}
