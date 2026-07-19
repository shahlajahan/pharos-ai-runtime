import 'package:pharos_ai_runtime/execution/execution_decision.dart';
import 'package:pharos_ai_runtime/runtime/engine/default_runtime_engine.dart';
import 'package:pharos_ai_runtime/runtime/intent/runtime_intent.dart';
import 'package:pharos_ai_runtime/runtime/plan/runtime_plan.dart';
import 'package:pharos_ai_runtime/runtime/planning/planning_request.dart';
import 'package:pharos_ai_runtime/runtime/planning/planning_result.dart';
import 'package:pharos_ai_runtime/runtime/planning/runtime_planner.dart';
import 'package:pharos_ai_runtime/runtime/workflow/workflow_builder.dart';
import 'package:pharos_ai_runtime/workflow/workflow.dart';
import 'package:pharos_ai_runtime/workflow/workflow_result.dart';
import 'package:test/test.dart';

class _FakeRuntimeIntent implements RuntimeIntent {
  @override
  String get id => 'i1';

  @override
  String get title => 'Release version 2.0';
}

class _FakeRuntimePlanner implements RuntimePlanner {
  _FakeRuntimePlanner(this.producedPlan);

  final RuntimePlan producedPlan;
  int callCount = 0;
  PlanningRequest? capturedRequest;

  @override
  Future<PlanningResult> plan(PlanningRequest request) async {
    callCount++;
    capturedRequest = request;

    return PlanningResult(plan: producedPlan);
  }
}

class _FakeWorkflow implements Workflow {
  _FakeWorkflow(this.result);

  final WorkflowResult result;
  int callCount = 0;
  ExecutionDecision? capturedDecision;

  @override
  Future<WorkflowResult> execute(ExecutionDecision decision) async {
    callCount++;
    capturedDecision = decision;

    return result;
  }
}

class _FakeWorkflowBuilder implements WorkflowBuilder {
  _FakeWorkflowBuilder(this.workflow);

  final Workflow workflow;
  int callCount = 0;
  RuntimePlan? capturedPlan;

  @override
  Future<Workflow> build(RuntimePlan plan) async {
    callCount++;
    capturedPlan = plan;

    return workflow;
  }
}

void main() {
  test('execute() calls planner.plan() exactly once', () async {
    const plan = RuntimePlan(id: 'p1', title: 'Ship the release');
    final planner = _FakeRuntimePlanner(plan);
    final workflow = _FakeWorkflow(WorkflowResult(stepResults: []));
    final workflowBuilder = _FakeWorkflowBuilder(workflow);
    const decision = ExecutionDecision(steps: []);
    final engine = DefaultRuntimeEngine(
      planner: planner,
      workflowBuilder: workflowBuilder,
      executionDecision: decision,
    );

    await engine.execute(_FakeRuntimeIntent());

    expect(planner.callCount, 1);
  });

  test('execute() passes the given RuntimeIntent to planner.plan() via '
      'PlanningRequest', () async {
    const plan = RuntimePlan(id: 'p1', title: 'Ship the release');
    final planner = _FakeRuntimePlanner(plan);
    final workflow = _FakeWorkflow(WorkflowResult(stepResults: []));
    final workflowBuilder = _FakeWorkflowBuilder(workflow);
    const decision = ExecutionDecision(steps: []);
    final engine = DefaultRuntimeEngine(
      planner: planner,
      workflowBuilder: workflowBuilder,
      executionDecision: decision,
    );
    final intent = _FakeRuntimeIntent();

    await engine.execute(intent);

    expect(planner.capturedRequest!.intent, same(intent));
  });

  test('execute() passes workflowBuilder.build() the RuntimePlan produced by '
      'planner.plan()', () async {
    const plan = RuntimePlan(id: 'p1', title: 'Ship the release');
    final planner = _FakeRuntimePlanner(plan);
    final workflow = _FakeWorkflow(WorkflowResult(stepResults: []));
    final workflowBuilder = _FakeWorkflowBuilder(workflow);
    const decision = ExecutionDecision(steps: []);
    final engine = DefaultRuntimeEngine(
      planner: planner,
      workflowBuilder: workflowBuilder,
      executionDecision: decision,
    );

    await engine.execute(_FakeRuntimeIntent());

    expect(workflowBuilder.callCount, 1);
    expect(workflowBuilder.capturedPlan, same(plan));
  });

  test('execute() calls workflow.execute() exactly once, with the given '
      'ExecutionDecision', () async {
    const plan = RuntimePlan(id: 'p1', title: 'Ship the release');
    final planner = _FakeRuntimePlanner(plan);
    final workflow = _FakeWorkflow(WorkflowResult(stepResults: []));
    final workflowBuilder = _FakeWorkflowBuilder(workflow);
    const decision = ExecutionDecision(steps: []);
    final engine = DefaultRuntimeEngine(
      planner: planner,
      workflowBuilder: workflowBuilder,
      executionDecision: decision,
    );

    await engine.execute(_FakeRuntimeIntent());

    expect(workflow.callCount, 1);
    expect(workflow.capturedDecision, same(decision));
  });

  test('execute() returns the WorkflowResult from workflow.execute() '
      'unchanged', () async {
    const plan = RuntimePlan(id: 'p1', title: 'Ship the release');
    final planner = _FakeRuntimePlanner(plan);
    final expectedResult = WorkflowResult(stepResults: []);
    final workflow = _FakeWorkflow(expectedResult);
    final workflowBuilder = _FakeWorkflowBuilder(workflow);
    const decision = ExecutionDecision(steps: []);
    final engine = DefaultRuntimeEngine(
      planner: planner,
      workflowBuilder: workflowBuilder,
      executionDecision: decision,
    );

    final result = await engine.execute(_FakeRuntimeIntent());

    expect(result, same(expectedResult));
  });
}
