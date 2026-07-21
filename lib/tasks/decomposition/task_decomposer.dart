import 'package:pharos_ai_runtime/tasks/decomposition/decomposition_result.dart';
import 'package:pharos_ai_runtime/tasks/models/task.dart';
import 'package:pharos_ai_runtime/tasks/models/task_dependency.dart';
import 'package:pharos_ai_runtime/tasks/models/task_priority.dart';
import 'package:pharos_ai_runtime/tasks/models/task_status.dart';
import 'package:pharos_ai_runtime/tasks/models/task_type.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_step.dart';
import 'package:pharos_ai_runtime/workflow/planner/workflow_instance.dart';

/// Metadata key a WorkflowStep may set to override [_defaultTaskDuration]
/// with an explicit estimate, in seconds (int or double) — the same
/// convention WorkflowSimulator uses for step duration estimates.
const _estimatedDurationSecondsKey = 'estimatedDurationSeconds';

/// The default duration assumed for a task with no explicit estimate.
/// An arbitrary but consistent baseline — this is only ever an
/// estimate, never a measurement.
const _defaultTaskDuration = Duration(minutes: 1);

/// Transforms a planned Workflow's steps into executable Tasks — the
/// smallest units of work a future Agent Runtime will assign. Knows
/// workflows, steps, and dependencies only; never agents, AI, tools,
/// APIs, HTTP, or CRM. Never executes anything.
class TaskDecomposer {
  const TaskDecomposer();

  DecompositionResult decompose(WorkflowInstance instance) {
    final steps = instance.steps;

    if (steps.isEmpty) {
      return const DecompositionResult(
        success: false,
        tasks: [],
        warnings: [],
        errors: ['Workflow has no steps to decompose.'],
      );
    }

    final warnings = <String>[];
    final stepIds = steps.map((step) => step.id).toSet();

    final missingDependencies = <String>{};
    for (final step in steps) {
      for (final dependsOnId in step.dependsOn) {
        if (!stepIds.contains(dependsOnId)) {
          missingDependencies.add(dependsOnId);
        }
      }
    }
    if (missingDependencies.isNotEmpty) {
      warnings.add(
        'Missing step dependencies: ${missingDependencies.join(', ')}.',
      );
    }

    final tasksByStep = {
      for (final step in steps) step.id: _decomposeStep(step),
    };

    final tasks = <Task>[];
    for (final step in steps) {
      final stepTasks = tasksByStep[step.id]!;
      final crossStepDependencies = [
        for (final dependsOnId in step.dependsOn)
          if (tasksByStep.containsKey(dependsOnId))
            TaskDependency(tasksByStep[dependsOnId]!.last.id),
      ];

      for (var i = 0; i < stepTasks.length; i++) {
        final task = stepTasks[i];
        final dependencies = [
          ...(i == 0
              ? crossStepDependencies
              : [TaskDependency(stepTasks[i - 1].id)]),
        ];

        tasks.add(
          Task(
            id: task.id,
            title: task.title,
            description: task.description,
            type: task.type,
            priority: task.priority,
            status: task.status,
            dependencies: dependencies,
            requiredCapabilities: task.requiredCapabilities,
            estimatedDuration: task.estimatedDuration,
            metadata: task.metadata,
          ),
        );
      }
    }

    return DecompositionResult(
      success: true,
      tasks: tasks,
      warnings: warnings,
      errors: const [],
    );
  }

  /// Preserves execution order within a step's own decomposition;
  /// cross-step dependencies are attached by [decompose] afterward, so
  /// every task built here starts with empty dependencies.
  List<Task> _decomposeStep(WorkflowStep step) {
    if (step.title.trim().toLowerCase() == 'generate images') {
      return _generateImagesTasks(step);
    }

    return [
      Task(
        id: step.id,
        title: step.title,
        description: step.description,
        type: TaskType.custom,
        priority: TaskPriority.medium,
        status: TaskStatus.pending,
        dependencies: const [],
        requiredCapabilities: const [],
        estimatedDuration: _taskDuration(step.metadata),
        metadata: step.metadata,
      ),
    ];
  }

  /// The roadmap's own worked example: a "Generate Images" step expands
  /// into six sequential tasks rather than a single 1:1 task, since
  /// image generation is genuinely composed of distinct executable
  /// units of work.
  List<Task> _generateImagesTasks(WorkflowStep step) {
    Task subTask(
      String suffix,
      String title,
      TaskType type,
      List<String> requiredCapabilities,
    ) => Task(
      id: '${step.id}.$suffix',
      title: title,
      description: '$title for "${step.title}".',
      type: type,
      priority: TaskPriority.medium,
      status: TaskStatus.pending,
      dependencies: const [],
      requiredCapabilities: requiredCapabilities,
      estimatedDuration: _defaultTaskDuration,
      metadata: const {},
    );

    return [
      subTask('research-style', 'Research Style', TaskType.research, const [
        'style-research',
      ]),
      subTask(
        'collect-references',
        'Collect References',
        TaskType.research,
        const ['reference-collection'],
      ),
      subTask('generate-prompt', 'Generate Prompt', TaskType.generation, const [
        'prompt-generation',
      ]),
      subTask('generate-images', 'Generate Images', TaskType.generation, const [
        'image-generation',
        'creative-design',
      ]),
      subTask('review-assets', 'Review Assets', TaskType.review, const [
        'asset-review',
      ]),
      subTask('store-assets', 'Store Assets', TaskType.storage, const [
        'asset-storage',
      ]),
    ];
  }

  Duration _taskDuration(Map<String, Object> metadata) {
    final estimate = metadata[_estimatedDurationSecondsKey];

    if (estimate is int) {
      return Duration(seconds: estimate);
    }
    if (estimate is double) {
      return Duration(milliseconds: (estimate * 1000).round());
    }

    return _defaultTaskDuration;
  }
}
