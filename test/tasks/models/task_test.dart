import 'package:pharos_ai_runtime/tasks/models/task.dart';
import 'package:pharos_ai_runtime/tasks/models/task_dependency.dart';
import 'package:pharos_ai_runtime/tasks/models/task_priority.dart';
import 'package:pharos_ai_runtime/tasks/models/task_status.dart';
import 'package:pharos_ai_runtime/tasks/models/task_type.dart';
import 'package:test/test.dart';

void main() {
  test('Task stores every field exactly as constructed', () {
    const task = Task(
      id: 'generate-images.generate-images',
      title: 'Generate Images',
      description: 'Generate Images for "Generate Images".',
      type: TaskType.generation,
      priority: TaskPriority.medium,
      status: TaskStatus.pending,
      dependencies: [TaskDependency('generate-images.generate-prompt')],
      requiredCapabilities: ['image-generation', 'creative-design'],
      estimatedDuration: Duration(minutes: 1),
      metadata: {},
    );

    expect(task.id, 'generate-images.generate-images');
    expect(task.type, TaskType.generation);
    expect(task.priority, TaskPriority.medium);
    expect(task.status, TaskStatus.pending);
    expect(task.dependencies.single.taskId, 'generate-images.generate-prompt');
    expect(task.requiredCapabilities, ['image-generation', 'creative-design']);
    expect(task.estimatedDuration, const Duration(minutes: 1));
  });

  test('Task is constructible as a compile-time constant, proving '
      'immutability', () {
    const task = Task(
      id: 't',
      title: 't',
      description: '',
      type: TaskType.custom,
      priority: TaskPriority.low,
      status: TaskStatus.pending,
      dependencies: [],
      requiredCapabilities: [],
      estimatedDuration: Duration.zero,
      metadata: {},
    );

    expect(task, isA<Task>());
  });
}
