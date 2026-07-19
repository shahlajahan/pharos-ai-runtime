import 'package:pharos_ai_runtime/execution/execution_decision.dart';
import 'package:pharos_ai_runtime/runtime/plan/runtime_plan.dart';
import 'package:pharos_ai_runtime/runtime/workflow/workflow_builder.dart';
import 'package:pharos_ai_runtime/workflow/workflow.dart';
import 'package:pharos_ai_runtime/workflow/workflow_result.dart';
import 'package:test/test.dart';

class _FakeWorkflow implements Workflow {
  @override
  Future<WorkflowResult> execute(ExecutionDecision decision) async {
    return const WorkflowResult(stepResults: []);
  }
}

class _FakeWorkflowBuilder implements WorkflowBuilder {
  @override
  Future<Workflow> build(RuntimePlan plan) async {
    return _FakeWorkflow();
  }
}

void main() {
  test('WorkflowBuilder can be implemented', () {
    final builder = _FakeWorkflowBuilder();

    expect(builder, isA<WorkflowBuilder>());
  });

  test('Fake builder returns a Workflow', () async {
    final builder = _FakeWorkflowBuilder();
    const plan = RuntimePlan(id: 'p1', title: 'Ship the release');

    final workflow = await builder.build(plan);

    expect(workflow, isA<Workflow>());
  });
}
