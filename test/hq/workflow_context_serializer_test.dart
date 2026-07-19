import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/hq/workflow_context_serializer.dart';
import 'package:pharos_ai_runtime/planner/plan_step.dart';
import 'package:pharos_ai_runtime/workflow/workflow_context.dart';
import 'package:pharos_ai_runtime/workflow/workflow_step_result.dart';
import 'package:test/test.dart';

void main() {
  const serializer = WorkflowContextSerializer();

  test('serialize() returns just the header for an empty context', () {
    const context = WorkflowContext(previousSteps: []);

    expect(serializer.serialize(context), 'Previous Workflow Results\n');
  });

  test('serialize() formats a single previous step deterministically', () {
    final context = WorkflowContext(
      previousSteps: [
        WorkflowStepResult(
          step: const PlanStep(
            description: 'Research competitors',
            assignedEmployee: 'research',
          ),
          result: Result.success('Competitor research complete.'),
        ),
      ],
    );

    expect(
      serializer.serialize(context),
      'Previous Workflow Results\n'
      '\n'
      '1.\n'
      '\n'
      'Employee:\n'
      'research\n'
      '\n'
      'Goal:\n'
      'Research competitors\n'
      '\n'
      'Result:\n'
      'Competitor research complete.\n',
    );
  });

  test('serialize() formats multiple previous steps, numbered in order', () {
    final context = WorkflowContext(
      previousSteps: [
        WorkflowStepResult(
          step: const PlanStep(
            description: 'Research competitors',
            assignedEmployee: 'research',
          ),
          result: Result.success('Competitor research complete.'),
        ),
        WorkflowStepResult(
          step: const PlanStep(
            description: 'Write launch copy',
            assignedEmployee: 'marketing',
          ),
          result: Result.success('Launch copy drafted.'),
        ),
      ],
    );

    expect(
      serializer.serialize(context),
      'Previous Workflow Results\n'
      '\n'
      '1.\n'
      '\n'
      'Employee:\n'
      'research\n'
      '\n'
      'Goal:\n'
      'Research competitors\n'
      '\n'
      'Result:\n'
      'Competitor research complete.\n'
      '\n'
      '2.\n'
      '\n'
      'Employee:\n'
      'marketing\n'
      '\n'
      'Goal:\n'
      'Write launch copy\n'
      '\n'
      'Result:\n'
      'Launch copy drafted.\n',
    );
  });

  test('serialize() is deterministic: the same context always serializes '
      'to the exact same String', () {
    final context = WorkflowContext(
      previousSteps: [
        WorkflowStepResult(
          step: const PlanStep(
            description: 'Research competitors',
            assignedEmployee: 'research',
          ),
          result: Result.success('Competitor research complete.'),
        ),
      ],
    );

    expect(serializer.serialize(context), serializer.serialize(context));
  });
}
