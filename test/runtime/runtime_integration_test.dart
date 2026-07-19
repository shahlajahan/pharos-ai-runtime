import 'package:pharos_ai_runtime/execution/execution_decision.dart';
import 'package:pharos_ai_runtime/runtime/engine/default_runtime_engine.dart';
import 'package:pharos_ai_runtime/runtime/intent/runtime_intent.dart';
import 'package:pharos_ai_runtime/runtime/planning/default_runtime_planner.dart';
import 'package:pharos_ai_runtime/runtime/workflow/default_workflow_builder.dart';
import 'package:pharos_ai_runtime/workflow/workflow_result.dart';
import 'package:test/test.dart';

class _FakeRuntimeIntent implements RuntimeIntent {
  @override
  String get id => 'intent-1';

  @override
  String get title => 'Ship v1';
}

void main() {
  test('RuntimeIntent -> DefaultRuntimeEngine -> DefaultRuntimePlanner -> '
      'DefaultWorkflowBuilder -> MinimalWorkflow -> WorkflowResult works '
      'end-to-end, using only the default implementations', () async {
    const planner = DefaultRuntimePlanner();
    const workflowBuilder = DefaultWorkflowBuilder();
    const decision = ExecutionDecision(steps: []);

    final engine = DefaultRuntimeEngine(
      planner: planner,
      workflowBuilder: workflowBuilder,
      executionDecision: decision,
    );

    final intent = _FakeRuntimeIntent();

    final result = await engine.execute(intent);

    expect(result, isA<WorkflowResult>());
    expect(result.stepResults, isEmpty);
  });
}
