import 'dart:io';

import 'package:pharos_ai_runtime/employees/employee_repository.dart';
import 'package:pharos_ai_runtime/employees/markdown_employee_parser.dart';
import 'package:pharos_ai_runtime/execution/immediate_execution_strategy.dart';
import 'package:pharos_ai_runtime/hq/employee_discovery.dart';
import 'package:pharos_ai_runtime/hq/employee_loader.dart';
import 'package:pharos_ai_runtime/hq/hq.dart';
import 'package:pharos_ai_runtime/hq/hq_bootstrap.dart';
import 'package:pharos_ai_runtime/hq/hq_validator.dart';
import 'package:pharos_ai_runtime/hq/local_hq_source.dart';
import 'package:pharos_ai_runtime/knowledge/knowledge_repository.dart';
import 'package:pharos_ai_runtime/knowledge/markdown_knowledge_parser.dart';
import 'package:pharos_ai_runtime/models/conversation.dart';
import 'package:pharos_ai_runtime/models/model_provider.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/models/model_response.dart';
import 'package:pharos_ai_runtime/planner/default_planner.dart';
import 'package:pharos_ai_runtime/execution/execution_decision.dart';
import 'package:pharos_ai_runtime/planner/plan_step.dart';
import 'package:pharos_ai_runtime/prompts/markdown_prompt_parser.dart';
import 'package:pharos_ai_runtime/prompts/prompt_repository.dart';
import 'package:pharos_ai_runtime/runtime/employee_factory.dart';
import 'package:pharos_ai_runtime/workflow/default_workflow.dart';
import 'package:test/test.dart';

/// Returns one scripted response per call, in order. This is the only
/// mock anywhere in this milestone test: everything downstream of a
/// ModelResponse — Planner, ExecutionStrategy, Workflow, WorkflowContext,
/// HQ (Employee resolution), and Runtime (Tool loop, response handling)
/// is the real, unmodified production pipeline.
class _ScriptedModelProvider extends ModelProvider {
  _ScriptedModelProvider(this._responses);

  final List<ModelResponse> _responses;
  final List<ModelRequest> capturedRequests = [];

  @override
  Future<ModelResponse> generate(ModelRequest request) async {
    capturedRequests.add(request);

    return _responses[capturedRequests.length - 1];
  }
}

void _writeEmployee(
  Directory hqDir, {
  required String id,
  required String name,
}) {
  final employeeDir = Directory('${hqDir.path}/employees/$id');
  employeeDir.createSync(recursive: true);
  File('${employeeDir.path}/employee.md').writeAsStringSync('''
id: $id
name: $name
role: $name
''');
  Directory('${employeeDir.path}/knowledge').createSync();
  Directory('${employeeDir.path}/prompts').createSync();
}

HQBootstrap _realBootstrap() => HQBootstrap(
  validator: HQValidator(),
  repository: EmployeeRepository(
    discovery: EmployeeDiscovery(),
    loader: EmployeeLoader(),
    parser: MarkdownEmployeeParser(),
  ),
  employeeFactory: EmployeeFactory(
    knowledgeRepository: KnowledgeRepository(parser: MarkdownKnowledgeParser()),
    promptRepository: PromptRepository(parser: MarkdownPromptParser()),
  ),
);

void main() {
  late Directory hqDir;

  setUp(() {
    hqDir = Directory.systemTemp.createTempSync(
      'first_end_to_end_multi_agent_test_',
    );
    Directory('${hqDir.path}/knowledge').createSync();

    _writeEmployee(hqDir, id: 'default', name: 'Default Employee');
    _writeEmployee(hqDir, id: 'research', name: 'Research Employee');
    _writeEmployee(hqDir, id: 'marketing', name: 'Marketing Employee');
    _writeEmployee(hqDir, id: 'reviewer', name: 'Reviewer Employee');
  });

  tearDown(() {
    if (hqDir.existsSync()) {
      hqDir.deleteSync(recursive: true);
    }
  });

  test('CEO Goal -> Planner -> Plan -> ImmediateExecutionStrategy -> '
      'ExecutionDecision -> Workflow -> HQ -> Runtime -> WorkflowResult, '
      'entirely through the real production pipeline, with the only mock '
      'being ModelProvider', () async {
    const ceoGoal =
        'Research competitors\nWrite marketing copy\nReview architecture';

    // Planner produces the Plan.
    const planner = DefaultPlanner();
    final plan = planner.plan(ceoGoal);
    expect(plan, isNotNull);
    expect(plan!.steps, hasLength(3));

    // ExecutionStrategy selects the PlanSteps.
    const strategy = ImmediateExecutionStrategy();
    final decision = strategy.decide(plan);
    expect(decision.steps, plan.steps);

    final modelProvider = _ScriptedModelProvider([
      const ModelResponse(text: 'Competitor research complete.'),
      const ModelResponse(text: 'Marketing copy drafted.'),
      const ModelResponse(text: 'Architecture reviewed.'),
    ]);

    // HQ resolves Employees; Runtime executes them.
    final hq = HQ(
      modelProvider: modelProvider,
      bootstrap: _realBootstrap(),
      source: LocalHQSource(hqDir.path),
    );

    // Workflow executes each assigned Employee, carrying WorkflowContext
    // forward step by step.
    final workflow = DefaultWorkflow(hq: hq);
    final workflowResult = await workflow.execute(decision);

    // Runtime executed exactly once per PlanStep, all for the "default"
    // Employee — DefaultPlanner does not yet infer distinct Employees
    // per step (see HQ-012); that capability belongs to a future AI
    // planner, not this milestone.
    expect(modelProvider.capturedRequests, hasLength(3));
    for (final request in modelProvider.capturedRequests) {
      final systemMessage =
          request.conversation.messages.first as SystemMessage;
      expect(systemMessage.content, contains('Default Employee'));
    }

    // WorkflowContext carried every previous output forward: turn 2 saw
    // turn 1's result, and turn 3 saw both turn 1's and turn 2's.
    UserMessage userMessageOf(int turn) => modelProvider
        .capturedRequests[turn]
        .conversation
        .messages
        .whereType<UserMessage>()
        .single;

    expect(userMessageOf(0).content, 'Research competitors');

    expect(userMessageOf(1).content, contains('Previous Workflow Results'));
    expect(userMessageOf(1).content, contains('Competitor research complete.'));
    expect(userMessageOf(1).content, endsWith('Write marketing copy'));

    expect(userMessageOf(2).content, contains('Competitor research complete.'));
    expect(userMessageOf(2).content, contains('Marketing copy drafted.'));
    expect(userMessageOf(2).content, endsWith('Review architecture'));

    // WorkflowResult contains every Result, one per PlanStep, in order.
    expect(workflowResult.stepResults, hasLength(3));
    expect(workflowResult.stepResults.map((r) => r.result.message), [
      'Competitor research complete.',
      'Marketing copy drafted.',
      'Architecture reviewed.',
    ]);
    expect(workflowResult.stepResults.every((r) => r.result.success), isTrue);
  });

  test(
    'Research Employee -> Marketing Employee (receives Research output) -> '
    'Reviewer Employee (receives Research + Marketing outputs) -> '
    'WorkflowResult, with three distinct real Employees each resolved by '
    'HQ and executed by Runtime through the real production pipeline',
    () async {
      // ExecutionDecision as ImmediateExecutionStrategy would produce it
      // for a Plan whose steps are each assigned a distinct Employee — the
      // multi-agent capability DefaultPlanner does not infer yet (HQ-012),
      // but that Workflow, HQ, and Runtime already fully support.
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
            assignedEmployee: 'reviewer',
          ),
        ],
      );

      final modelProvider = _ScriptedModelProvider([
        const ModelResponse(text: 'Competitor research complete.'),
        const ModelResponse(text: 'Marketing copy drafted.'),
        const ModelResponse(text: 'Architecture reviewed.'),
      ]);

      final hq = HQ(
        modelProvider: modelProvider,
        bootstrap: _realBootstrap(),
        source: LocalHQSource(hqDir.path),
      );

      final workflow = DefaultWorkflow(hq: hq);
      final workflowResult = await workflow.execute(decision);

      expect(modelProvider.capturedRequests, hasLength(3));

      // Each turn resolved and executed a distinct, real Employee.
      SystemMessage systemMessageOf(int turn) =>
          modelProvider.capturedRequests[turn].conversation.messages.first
              as SystemMessage;
      expect(systemMessageOf(0).content, contains('Research Employee'));
      expect(systemMessageOf(1).content, contains('Marketing Employee'));
      expect(systemMessageOf(2).content, contains('Reviewer Employee'));

      UserMessage userMessageOf(int turn) => modelProvider
          .capturedRequests[turn]
          .conversation
          .messages
          .whereType<UserMessage>()
          .single;

      // Marketing receives Research's output.
      expect(userMessageOf(1).content, contains('Employee:\nresearch'));
      expect(
        userMessageOf(1).content,
        contains('Competitor research complete.'),
      );

      // Reviewer receives every previous output — both Research's and
      // Marketing's — in order.
      final reviewerContent = userMessageOf(2).content;
      expect(reviewerContent, contains('Employee:\nresearch'));
      expect(reviewerContent, contains('Competitor research complete.'));
      expect(reviewerContent, contains('Employee:\nmarketing'));
      expect(reviewerContent, contains('Marketing copy drafted.'));
      final researchIndex = reviewerContent.indexOf('Competitor research');
      final marketingIndex = reviewerContent.indexOf('Marketing copy drafted');
      expect(marketingIndex, greaterThan(researchIndex));

      // WorkflowResult contains every Result, one per PlanStep, in order.
      expect(workflowResult.stepResults, hasLength(3));
      expect(workflowResult.stepResults.map((r) => r.step.assignedEmployee), [
        'research',
        'marketing',
        'reviewer',
      ]);
      expect(workflowResult.stepResults.map((r) => r.result.message), [
        'Competitor research complete.',
        'Marketing copy drafted.',
        'Architecture reviewed.',
      ]);
      expect(workflowResult.stepResults.every((r) => r.result.success), isTrue);
    },
  );
}
