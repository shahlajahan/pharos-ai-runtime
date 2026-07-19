import 'package:pharos_ai_runtime/execution/execution_decision.dart';
import 'package:pharos_ai_runtime/runtime/plan/runtime_plan.dart';
import 'package:pharos_ai_runtime/runtime/workflow/default_workflow_builder.dart';
import 'package:pharos_ai_runtime/workflow/workflow.dart';
import 'package:pharos_ai_runtime/workflow/workflow_result.dart';
import 'package:test/test.dart';

void main() {
  test('build() returns a Workflow', () async {
    const builder = DefaultWorkflowBuilder();
    const plan = RuntimePlan(id: 'p1', title: 'Ship the release');

    final workflow = await builder.build(plan);

    expect(workflow, isA<Workflow>());
  });

  test(
    'the produced Workflow can execute, propagating its WorkflowResult',
    () async {
      const builder = DefaultWorkflowBuilder();
      const plan = RuntimePlan(id: 'p1', title: 'Ship the release');

      final workflow = await builder.build(plan);
      final result = await workflow.execute(const ExecutionDecision(steps: []));

      expect(result, isA<WorkflowResult>());
      expect(result.stepResults, isEmpty);
    },
  );
}
