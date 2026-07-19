import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/execution/execution_decision.dart';
import 'package:pharos_ai_runtime/hq/hq.dart';
import 'package:pharos_ai_runtime/hq/hq_boot_result.dart';
import 'package:pharos_ai_runtime/hq/hq_bootstrapper.dart';
import 'package:pharos_ai_runtime/hq/hq_source.dart';
import 'package:pharos_ai_runtime/memory/conversation_memory.dart';
import 'package:pharos_ai_runtime/models/model_provider.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/models/model_response.dart';
import 'package:pharos_ai_runtime/planner/plan_step.dart';
import 'package:pharos_ai_runtime/workflow/default_workflow.dart';
import 'package:pharos_ai_runtime/workflow/workflow_context.dart';
import 'package:test/test.dart';

class _FakeHQSource extends HQSource {
  @override
  Future<String> rootPath() async => '/fake/hq';
}

class _FakeModelProvider extends ModelProvider {
  @override
  Future<ModelResponse> generate(ModelRequest request) async =>
      const ModelResponse(text: 'unused');
}

class _FakeHQBootstrapper extends HQBootstrapper {
  @override
  Future<HQBootResult> boot(HQSource source) async =>
      HQBootResult(result: Result.success('booted'), employees: const []);
}

/// Spies on HQ.invoke() without exercising the real boot/Runtime pipeline,
/// so DefaultWorkflow's orchestration can be tested in isolation — exactly
/// the same pattern DelegateEmployeeTool's own tests use to spy on HQ.
class _SpyHQ extends HQ {
  _SpyHQ()
    : super(
        modelProvider: _FakeModelProvider(),
        bootstrap: _FakeHQBootstrapper(),
        source: _FakeHQSource(),
      );

  final List<String> invokedEmployees = [];
  final List<String> invokedGoals = [];
  final List<WorkflowContext?> invokedContexts = [];
  final Map<String, Result> responses = {};
  Result defaultResponse = Result.success('done');

  @override
  Future<Result> invoke({
    required String employee,
    required String goal,
    ConversationMemory? memory,
    WorkflowContext? context,
  }) async {
    invokedEmployees.add(employee);
    invokedGoals.add(goal);
    invokedContexts.add(context);

    return responses[employee] ?? defaultResponse;
  }
}

void main() {
  test('execute() calls HQ.invoke() exactly once per PlanStep', () async {
    final hq = _SpyHQ();
    final workflow = DefaultWorkflow(hq: hq);
    const decision = ExecutionDecision(
      steps: [
        PlanStep(description: 'Research', assignedEmployee: 'default'),
        PlanStep(description: 'Write', assignedEmployee: 'default'),
        PlanStep(description: 'Publish', assignedEmployee: 'default'),
      ],
    );

    await workflow.execute(decision);

    expect(hq.invokedEmployees, ['default', 'default', 'default']);
  });

  test(
    "execute() calls HQ.invoke() with each PlanStep's own assignedEmployee "
    'and description, so different steps may target different Employees',
    () async {
      final hq = _SpyHQ();
      final workflow = DefaultWorkflow(hq: hq);
      const decision = ExecutionDecision(
        steps: [
          PlanStep(
            description: 'Research competitors',
            assignedEmployee: 'research',
          ),
          PlanStep(
            description: 'Write marketing copy',
            assignedEmployee: 'marketing',
          ),
          PlanStep(
            description: 'Review architecture',
            assignedEmployee: 'architect',
          ),
        ],
      );

      await workflow.execute(decision);

      expect(hq.invokedEmployees, ['research', 'marketing', 'architect']);
      expect(hq.invokedGoals, [
        'Research competitors',
        'Write marketing copy',
        'Review architecture',
      ]);
    },
  );

  test('execute() returns a WorkflowResult pairing each PlanStep with the '
      "Result HQ.invoke() produced for it, in order", () async {
    final hq = _SpyHQ()
      ..responses['research'] = Result.success('research done')
      ..responses['marketing'] = Result.success('copy written');
    final workflow = DefaultWorkflow(hq: hq);
    const decision = ExecutionDecision(
      steps: [
        PlanStep(description: 'Research', assignedEmployee: 'research'),
        PlanStep(description: 'Write', assignedEmployee: 'marketing'),
      ],
    );

    final result = await workflow.execute(decision);

    expect(result.stepResults, hasLength(2));
    expect(result.stepResults[0].step.assignedEmployee, 'research');
    expect(result.stepResults[0].result.message, 'research done');
    expect(result.stepResults[1].step.assignedEmployee, 'marketing');
    expect(result.stepResults[1].result.message, 'copy written');
  });

  test('execute() returns an empty WorkflowResult for an empty '
      'ExecutionDecision, without calling HQ.invoke()', () async {
    final hq = _SpyHQ();
    final workflow = DefaultWorkflow(hq: hq);
    const decision = ExecutionDecision(steps: []);

    final result = await workflow.execute(decision);

    expect(result.stepResults, isEmpty);
    expect(hq.invokedEmployees, isEmpty);
  });

  test('execute() invokes steps sequentially, in the given order', () async {
    final hq = _SpyHQ();
    final workflow = DefaultWorkflow(hq: hq);
    const decision = ExecutionDecision(
      steps: [
        PlanStep(description: 'first step', assignedEmployee: 'default'),
        PlanStep(description: 'second step', assignedEmployee: 'default'),
      ],
    );

    await workflow.execute(decision);

    expect(hq.invokedGoals, ['first step', 'second step']);
  });

  test(
    'execute() invokes the first step with an empty WorkflowContext',
    () async {
      final hq = _SpyHQ();
      final workflow = DefaultWorkflow(hq: hq);
      const decision = ExecutionDecision(
        steps: [
          PlanStep(description: 'Research', assignedEmployee: 'research'),
        ],
      );

      await workflow.execute(decision);

      expect(hq.invokedContexts.single, isNotNull);
      expect(hq.invokedContexts.single!.previousSteps, isEmpty);
    },
  );

  test(
    'execute() carries every previous WorkflowStepResult forward into the '
    "next step's WorkflowContext, so later steps see earlier outputs",
    () async {
      final hq = _SpyHQ()
        ..responses['research'] = Result.success(
          'Competitor research complete.',
        )
        ..responses['marketing'] = Result.success('Launch copy drafted.');
      final workflow = DefaultWorkflow(hq: hq);
      const decision = ExecutionDecision(
        steps: [
          PlanStep(
            description: 'Research competitors',
            assignedEmployee: 'research',
          ),
          PlanStep(
            description: 'Write launch copy',
            assignedEmployee: 'marketing',
          ),
          PlanStep(
            description: 'Review architecture',
            assignedEmployee: 'architect',
          ),
        ],
      );

      await workflow.execute(decision);

      expect(hq.invokedContexts, hasLength(3));

      // Step 1 (research): nothing came before it.
      expect(hq.invokedContexts[0]!.previousSteps, isEmpty);

      // Step 2 (marketing): sees only step 1's output.
      final step2Context = hq.invokedContexts[1]!;
      expect(step2Context.previousSteps, hasLength(1));
      expect(step2Context.previousSteps[0].step.assignedEmployee, 'research');
      expect(
        step2Context.previousSteps[0].result.message,
        'Competitor research complete.',
      );

      // Step 3 (architect/reviewer): sees both previous outputs, in order.
      final step3Context = hq.invokedContexts[2]!;
      expect(step3Context.previousSteps, hasLength(2));
      expect(step3Context.previousSteps[0].step.assignedEmployee, 'research');
      expect(step3Context.previousSteps[1].step.assignedEmployee, 'marketing');
      expect(
        step3Context.previousSteps[1].result.message,
        'Launch copy drafted.',
      );
    },
  );
}
