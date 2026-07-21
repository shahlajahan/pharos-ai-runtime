import 'package:pharos_ai_runtime/execution/runtime/execution_scheduler.dart';
import 'package:pharos_ai_runtime/tasks/models/task.dart';
import 'package:pharos_ai_runtime/tasks/models/task_dependency.dart';
import 'package:pharos_ai_runtime/tasks/models/task_priority.dart';
import 'package:pharos_ai_runtime/tasks/models/task_status.dart';
import 'package:pharos_ai_runtime/tasks/models/task_type.dart';
import 'package:test/test.dart';

Task _task(String id, {List<String> dependsOn = const []}) => Task(
  id: id,
  title: id,
  description: '',
  type: TaskType.generation,
  priority: TaskPriority.medium,
  status: TaskStatus.pending,
  dependencies: [
    for (final dependency in dependsOn) TaskDependency(dependency),
  ],
  requiredCapabilities: const [],
  estimatedDuration: const Duration(minutes: 1),
  metadata: const {},
);

void main() {
  const scheduler = ExecutionScheduler();

  test('executableTasks() returns a task with no dependencies', () {
    final tasks = [
      _task('a'),
      _task('b', dependsOn: ['a']),
    ];

    expect(scheduler.executableTasks(tasks, {}, {}).map((t) => t.id), ['a']);
  });

  test('executableTasks() returns every independent task together, for '
      'parallel scheduling', () {
    final tasks = [
      _task('a'),
      _task('b'),
      _task('c', dependsOn: ['a']),
    ];

    expect(scheduler.executableTasks(tasks, {}, {}).map((t) => t.id), [
      'a',
      'b',
    ]);
  });

  test('executableTasks() unblocks a task once its dependency is '
      'completed', () {
    final tasks = [
      _task('a'),
      _task('b', dependsOn: ['a']),
    ];

    expect(scheduler.executableTasks(tasks, {'a'}, {'a'}).map((t) => t.id), [
      'b',
    ]);
  });

  test('executableTasks() excludes terminal tasks even once their '
      'dependencies are satisfied', () {
    final tasks = [
      _task('a'),
      _task('b', dependsOn: ['a']),
    ];

    expect(scheduler.executableTasks(tasks, {'a'}, {'a', 'b'}), isEmpty);
  });

  test('isComplete() is true only once every task is terminal', () {
    final tasks = [_task('a'), _task('b')];

    expect(scheduler.isComplete(tasks, {'a', 'b'}), isTrue);
    expect(scheduler.isComplete(tasks, {'a'}), isFalse);
  });

  test('isDeadlocked() is true for a circular dependency', () {
    final tasks = [
      _task('a', dependsOn: ['b']),
      _task('b', dependsOn: ['a']),
    ];

    expect(scheduler.isDeadlocked(tasks, {}, {}), isTrue);
  });

  test('isDeadlocked() is false once every task is complete', () {
    final tasks = [_task('a')];

    expect(scheduler.isDeadlocked(tasks, {'a'}, {'a'}), isFalse);
  });

  test('isDeadlocked() is false while progress remains possible', () {
    final tasks = [
      _task('a'),
      _task('b', dependsOn: ['a']),
    ];

    expect(scheduler.isDeadlocked(tasks, {}, {}), isFalse);
  });

  test('is deterministic for the same inputs', () {
    final tasks = [
      _task('a'),
      _task('b', dependsOn: ['a']),
    ];

    expect(
      scheduler.executableTasks(tasks, {}, {}).map((t) => t.id),
      scheduler.executableTasks(tasks, {}, {}).map((t) => t.id),
    );
  });
}
