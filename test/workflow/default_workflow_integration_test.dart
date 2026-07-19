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
import 'package:pharos_ai_runtime/planner/plan_step.dart';
import 'package:pharos_ai_runtime/execution/execution_decision.dart';
import 'package:pharos_ai_runtime/prompts/markdown_prompt_parser.dart';
import 'package:pharos_ai_runtime/prompts/prompt_repository.dart';
import 'package:pharos_ai_runtime/runtime/employee_factory.dart';
import 'package:pharos_ai_runtime/workflow/default_workflow.dart';
import 'package:test/test.dart';

/// Returns one scripted response per call, in order, simulating one model
/// turn per HQ.invoke() call. This is the only fake in this test:
/// everything downstream — Planner, ExecutionStrategy, Workflow, HQ, and
/// Runtime — is the real, unmodified production pipeline.
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
      'default_workflow_integration_test_',
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

  test('Goal -> Planner -> Plan -> ExecutionStrategy -> ExecutionDecision -> '
      'Workflow.execute() -> HQ.invoke() once per PlanStep -> WorkflowResult, '
      'entirely through the real Planner + ExecutionStrategy + HQ + Runtime '
      'pipeline', () async {
    const goal = 'Research competitors\nDraft the announcement\nPublish it';

    // Real Planner: a 3-line goal is complex, producing 3 PlanSteps, all
    // assigned to the "default" Employee.
    const planner = DefaultPlanner();
    final plan = planner.plan(goal);
    expect(plan, isNotNull);
    expect(plan!.steps, hasLength(3));
    expect(
      plan.steps.every((step) => step.assignedEmployee == 'default'),
      isTrue,
    );

    // Real ExecutionStrategy: selects every PlanStep, in order.
    const strategy = ImmediateExecutionStrategy();
    final decision = strategy.decide(plan);

    final modelProvider = _ScriptedModelProvider([
      const ModelResponse(text: 'Competitor research complete.'),
      const ModelResponse(text: 'Announcement drafted.'),
      const ModelResponse(text: 'Published.'),
    ]);

    final hq = HQ(
      modelProvider: modelProvider,
      bootstrap: _realBootstrap(),
      source: LocalHQSource(hqDir.path),
    );

    final workflow = DefaultWorkflow(hq: hq);

    final workflowResult = await workflow.execute(decision);

    // HQ.invoke() (and therefore Runtime) invoked exactly once per
    // PlanStep, always for the "default" Employee.
    expect(modelProvider.capturedRequests, hasLength(3));
    for (final request in modelProvider.capturedRequests) {
      final systemMessage =
          request.conversation.messages.first as SystemMessage;
      expect(systemMessage.content, contains('Default Employee'));
    }

    // WorkflowResult pairs each PlanStep with its HQ-produced Result, in
    // the original order.
    expect(workflowResult.stepResults, hasLength(3));
    expect(workflowResult.stepResults.map((r) => r.step.description), [
      'Research competitors',
      'Draft the announcement',
      'Publish it',
    ]);
    expect(workflowResult.stepResults.map((r) => r.result.message), [
      'Competitor research complete.',
      'Announcement drafted.',
      'Published.',
    ]);
    expect(workflowResult.stepResults.every((r) => r.result.success), isTrue);
  });

  test('Different PlanSteps targeting different assignedEmployees are each '
      "routed to their own Employee through HQ.invoke(), proving Workflow "
      'does not assume every step belongs to the same Employee', () async {
    const decision = ExecutionDecision(
      steps: [
        PlanStep(
          description: 'Research the competitive landscape',
          assignedEmployee: 'research',
        ),
        PlanStep(
          description: 'Write the launch announcement',
          assignedEmployee: 'marketing',
        ),
      ],
    );

    final modelProvider = _ScriptedModelProvider([
      const ModelResponse(text: 'Research findings.'),
      const ModelResponse(text: 'Announcement copy.'),
    ]);

    final hq = HQ(
      modelProvider: modelProvider,
      bootstrap: _realBootstrap(),
      source: LocalHQSource(hqDir.path),
    );

    final workflow = DefaultWorkflow(hq: hq);

    final workflowResult = await workflow.execute(decision);

    expect(modelProvider.capturedRequests, hasLength(2));

    // Turn 1 was resolved and executed for the "research" Employee.
    final firstSystemMessage =
        modelProvider.capturedRequests[0].conversation.messages.first
            as SystemMessage;
    expect(firstSystemMessage.content, contains('Research Employee'));

    // Turn 2 was resolved and executed for the "marketing" Employee —
    // a different Employee than turn 1, in the same Workflow.execute()
    // call.
    final secondSystemMessage =
        modelProvider.capturedRequests[1].conversation.messages.first
            as SystemMessage;
    expect(secondSystemMessage.content, contains('Marketing Employee'));

    expect(workflowResult.stepResults, hasLength(2));
    expect(workflowResult.stepResults[0].step.assignedEmployee, 'research');
    expect(workflowResult.stepResults[0].result.message, 'Research findings.');
    expect(workflowResult.stepResults[1].step.assignedEmployee, 'marketing');
    expect(workflowResult.stepResults[1].result.message, 'Announcement copy.');
  });

  test('Research -> Marketing -> Reviewer: Marketing receives Research\'s '
      'output, and Reviewer receives both previous outputs, entirely '
      'through the real HQ + Runtime pipeline, with WorkflowResult '
      'unchanged', () async {
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
          assignedEmployee: 'reviewer',
        ),
      ],
    );

    final modelProvider = _ScriptedModelProvider([
      const ModelResponse(text: 'Competitor research complete.'),
      const ModelResponse(text: 'Launch copy drafted.'),
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

    UserMessage userMessageOf(int turn) => modelProvider
        .capturedRequests[turn]
        .conversation
        .messages
        .whereType<UserMessage>()
        .single;

    // Turn 1 (Research): no previous step exists yet, so the prompt is
    // the bare goal — unchanged from before WorkflowContext existed.
    expect(userMessageOf(0).content, 'Research competitors');

    // Turn 2 (Marketing): receives a deterministic summary of Research's
    // output before its own goal.
    final marketingContent = userMessageOf(1).content;
    expect(marketingContent, contains('Previous Workflow Results'));
    expect(marketingContent, contains('Employee:\nresearch'));
    expect(marketingContent, contains('Competitor research complete.'));
    expect(marketingContent, contains('Current Goal'));
    expect(marketingContent, endsWith('Write launch copy'));
    // Marketing's own output has not happened yet, so it cannot appear.
    expect(marketingContent, isNot(contains('Launch copy drafted.')));

    // Turn 3 (Reviewer): receives both previous outputs, in order.
    final reviewerContent = userMessageOf(2).content;
    expect(reviewerContent, contains('Employee:\nresearch'));
    expect(reviewerContent, contains('Competitor research complete.'));
    expect(reviewerContent, contains('Employee:\nmarketing'));
    expect(reviewerContent, contains('Launch copy drafted.'));
    expect(reviewerContent, contains('Current Goal'));
    expect(reviewerContent, endsWith('Review architecture'));
    final researchIndex = reviewerContent.indexOf('research');
    final marketingIndex = reviewerContent.indexOf('marketing');
    expect(researchIndex, greaterThanOrEqualTo(0));
    expect(marketingIndex, greaterThan(researchIndex));

    // WorkflowResult itself remains unchanged in shape: one
    // WorkflowStepResult per PlanStep, in order.
    expect(workflowResult.stepResults, hasLength(3));
    expect(workflowResult.stepResults.map((r) => r.step.assignedEmployee), [
      'research',
      'marketing',
      'reviewer',
    ]);
    expect(workflowResult.stepResults.map((r) => r.result.message), [
      'Competitor research complete.',
      'Launch copy drafted.',
      'Architecture reviewed.',
    ]);
  });
}
