import 'package:pharos_ai_runtime/agents/runtime/agent_runtime.dart';
import 'package:pharos_ai_runtime/execution/events/execution_event.dart';
import 'package:pharos_ai_runtime/execution/models/execution.dart';
import 'package:pharos_ai_runtime/execution/models/execution_id.dart';
import 'package:pharos_ai_runtime/execution/models/execution_result.dart';
import 'package:pharos_ai_runtime/execution/models/execution_status.dart';
import 'package:pharos_ai_runtime/execution/models/execution_step.dart';
import 'package:pharos_ai_runtime/execution/runtime/execution_context.dart';
import 'package:pharos_ai_runtime/execution/runtime/execution_monitor.dart';
import 'package:pharos_ai_runtime/execution/runtime/execution_scheduler.dart';
import 'package:pharos_ai_runtime/tasks/models/task.dart';
import 'package:pharos_ai_runtime/tools/models/tool_capability.dart';
import 'package:pharos_ai_runtime/tools/models/tool_request.dart';
import 'package:pharos_ai_runtime/tools/models/tool_result.dart';
import 'package:pharos_ai_runtime/tools/runtime/tool_runtime.dart';

/// Coordinates the execution of a workflow's tasks: the only component
/// allowed to execute work. Schedules executable rounds, asks the
/// Agent Runtime for assignments, asks the Tool Runtime to invoke each
/// assigned task, retries tool failures, and produces an
/// ExecutionResult. Knows workflow, tasks, agents, tools, and execution
/// state only — never business rules, marketing, finance, or
/// product-specific logic.
class ExecutionEngine {
  const ExecutionEngine({
    required this.agentRuntime,
    required this.toolRuntime,
    this.scheduler = const ExecutionScheduler(),
    this.maxRetries = 1,
  });

  final AgentRuntime agentRuntime;
  final ToolRuntime toolRuntime;
  final ExecutionScheduler scheduler;

  /// How many additional attempts a failing tool invocation gets before
  /// its task is reported as failed.
  final int maxRetries;

  /// Runs [context] to completion (or until paused, cancelled, or
  /// deadlocked), returning both the detailed [Execution] state and the
  /// summary [ExecutionResult] report.
  ///
  /// [controlSignal], when provided, is checked before every round: a
  /// [ExecutionStatus.paused] or [ExecutionStatus.cancelled] result
  /// stops the run early. This is the hook Future Compatibility's pause
  /// and cancel support hangs off, without changing this method's
  /// signature.
  ({Execution execution, ExecutionResult result}) run(
    ExecutionContext context, {
    ExecutionStatus? Function()? controlSignal,
  }) {
    final monitor = ExecutionMonitor();
    final startedAt = DateTime.now();
    final tasks = context.tasks;

    final completed = <String>{};
    final failed = <String>{};
    final cancelled = <String>{};
    final steps = <ExecutionStep>[];
    final results = <ToolResult>[];
    final artifacts = <String>[];

    monitor.recordEvent(
      ExecutionEventType.executionStarted,
      message: 'Execution started for workflow "${context.workflow.id}".',
    );

    var status = ExecutionStatus.running;

    Set<String> terminal() => {...completed, ...failed, ...cancelled};

    while (!scheduler.isComplete(tasks, terminal())) {
      final signal = controlSignal?.call();

      if (signal == ExecutionStatus.paused) {
        status = ExecutionStatus.paused;
        monitor.recordEvent(
          ExecutionEventType.executionPaused,
          message: 'Execution paused before starting a new round.',
        );
        break;
      }

      if (signal == ExecutionStatus.cancelled) {
        status = ExecutionStatus.cancelled;
        monitor.recordEvent(
          ExecutionEventType.executionCancelled,
          message: 'Execution cancelled before starting a new round.',
        );
        for (final task in tasks) {
          if (!terminal().contains(task.id)) {
            cancelled.add(task.id);
            steps.add(
              ExecutionStep(taskId: task.id, status: ExecutionStatus.cancelled),
            );
          }
        }
        break;
      }

      final round = scheduler.executableTasks(tasks, completed, terminal());

      if (round.isEmpty) {
        status = ExecutionStatus.failed;
        for (final task in tasks) {
          if (!terminal().contains(task.id)) {
            failed.add(task.id);
            monitor.captureFailure(
              task.id,
              'deadlock detected: an unresolved dependency will never '
              'complete.',
            );
            steps.add(
              ExecutionStep(taskId: task.id, status: ExecutionStatus.failed),
            );
          }
        }
        break;
      }

      final assignmentResult = agentRuntime.assign(round);
      final assignmentByTaskId = {
        for (final assignment in assignmentResult.assignments)
          assignment.taskId: assignment,
      };

      for (final task in round) {
        monitor.recordEvent(
          ExecutionEventType.taskStarted,
          taskId: task.id,
          message: 'Task "${task.id}" started.',
        );
        final taskStartedAt = DateTime.now();

        final assignment = assignmentByTaskId[task.id];
        if (assignment == null) {
          failed.add(task.id);
          monitor.captureFailure(task.id, 'no agent available.');
          monitor.recordEvent(
            ExecutionEventType.taskFailed,
            taskId: task.id,
            message: 'No agent available for task "${task.id}".',
          );
          steps.add(
            ExecutionStep(
              taskId: task.id,
              status: ExecutionStatus.failed,
              startedAt: taskStartedAt,
              finishedAt: DateTime.now(),
            ),
          );
          continue;
        }

        final request = _requestFor(task);
        var toolResult = toolRuntime.invoke(request);
        var attempts = 1;
        monitor.recordEvent(
          ExecutionEventType.toolInvoked,
          taskId: task.id,
          message: 'Invoking tool for task "${task.id}" (attempt $attempts).',
        );
        monitor.recordEvent(
          ExecutionEventType.toolFinished,
          taskId: task.id,
          message:
              'Tool finished for task "${task.id}" with '
              'success=${toolResult.success}.',
        );

        while (!toolResult.success && attempts <= maxRetries) {
          attempts++;
          monitor.recordWarning(
            'Task "${task.id}" retrying (attempt $attempts).',
          );
          monitor.recordEvent(
            ExecutionEventType.taskRetried,
            taskId: task.id,
            message: 'Retrying task "${task.id}" (attempt $attempts).',
          );
          toolResult = toolRuntime.invoke(request);
          monitor.recordEvent(
            ExecutionEventType.toolInvoked,
            taskId: task.id,
            message: 'Invoking tool for task "${task.id}" (attempt $attempts).',
          );
          monitor.recordEvent(
            ExecutionEventType.toolFinished,
            taskId: task.id,
            message:
                'Tool finished for task "${task.id}" with '
                'success=${toolResult.success}.',
          );
        }

        results.add(toolResult);
        artifacts.addAll(toolResult.artifacts);

        if (toolResult.success) {
          completed.add(task.id);
          monitor.recordEvent(
            ExecutionEventType.taskCompleted,
            taskId: task.id,
            message: 'Task "${task.id}" completed.',
          );
          steps.add(
            ExecutionStep(
              taskId: task.id,
              status: ExecutionStatus.completed,
              assignedAgent: assignment.agentId,
              startedAt: taskStartedAt,
              finishedAt: DateTime.now(),
              result: toolResult,
            ),
          );
        } else {
          failed.add(task.id);
          monitor.captureFailure(task.id, toolResult.errors.join(' '));
          monitor.recordEvent(
            ExecutionEventType.taskFailed,
            taskId: task.id,
            message: 'Task "${task.id}" failed after $attempts attempt(s).',
          );
          steps.add(
            ExecutionStep(
              taskId: task.id,
              status: ExecutionStatus.failed,
              assignedAgent: assignment.agentId,
              startedAt: taskStartedAt,
              finishedAt: DateTime.now(),
              result: toolResult,
            ),
          );
        }
      }
    }

    if (status == ExecutionStatus.running) {
      status = failed.isEmpty
          ? ExecutionStatus.completed
          : ExecutionStatus.failed;
      if (status == ExecutionStatus.completed) {
        monitor.recordEvent(
          ExecutionEventType.workflowCompleted,
          message: 'Workflow "${context.workflow.id}" completed.',
        );
      }
    }

    final finishedAt = DateTime.now();
    monitor.recordEvent(
      ExecutionEventType.executionFinished,
      message: 'Execution finished with status ${status.name}.',
    );

    monitor.recordMetric('totalTasks', tasks.length);
    monitor.recordMetric('completedTasks', completed.length);
    monitor.recordMetric('failedTasks', failed.length);
    monitor.recordMetric('cancelledTasks', cancelled.length);

    final execution = Execution(
      id: ExecutionId(
        'exec-${context.workflow.id}-${startedAt.microsecondsSinceEpoch}',
      ),
      workflowId: context.workflow.id,
      status: status,
      steps: steps,
      results: results,
      metrics: monitor.metrics,
      startedAt: startedAt,
      finishedAt: finishedAt,
    );

    final errors = [...monitor.failures];
    if (status == ExecutionStatus.cancelled) {
      errors.add('Execution was cancelled before completion.');
    }

    final warnings = [...monitor.warnings];
    if (status == ExecutionStatus.paused) {
      warnings.add('Execution paused before completion.');
    }

    final result = ExecutionResult(
      success: status == ExecutionStatus.completed,
      failedTasks: [...failed, ...cancelled],
      completedTasks: completed.toList(),
      duration: finishedAt.difference(startedAt),
      artifacts: artifacts,
      warnings: warnings,
      errors: errors,
      metrics: monitor.metrics,
    );

    return (execution: execution, result: result);
  }

  /// Builds the ToolRequest for [task]. The requested operation reuses
  /// the Task's own type name — deterministic, and free of any
  /// business-specific mapping.
  ToolRequest _requestFor(Task task) => ToolRequest(
    taskId: task.id,
    requestedCapabilities: {
      for (final capability in task.requiredCapabilities)
        ToolCapability(capability),
    },
    operation: task.type.name,
    parameters: task.metadata,
    timeout: task.estimatedDuration > Duration.zero
        ? task.estimatedDuration
        : const Duration(seconds: 30),
    metadata: const {},
  );
}
