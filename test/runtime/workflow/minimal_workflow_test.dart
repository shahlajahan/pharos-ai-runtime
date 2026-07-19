import 'package:pharos_ai_runtime/execution/execution_decision.dart';
import 'package:pharos_ai_runtime/runtime/workflow/minimal_workflow.dart';
import 'package:pharos_ai_runtime/workflow/workflow.dart';
import 'package:test/test.dart';

void main() {
  test('MinimalWorkflow implements Workflow', () {
    const workflow = MinimalWorkflow();

    expect(workflow, isA<Workflow>());
  });

  test('execute() returns an empty WorkflowResult', () async {
    const workflow = MinimalWorkflow();

    final result = await workflow.execute(const ExecutionDecision(steps: []));

    expect(result.stepResults, isEmpty);
  });
}
