import 'dart:io';

import 'package:pharos_ai_runtime/company/company_loader.dart';
import 'package:pharos_ai_runtime/core/agent.dart';
import 'package:pharos_ai_runtime/core/context.dart';
import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/decision/decision_engine.dart';
import 'package:pharos_ai_runtime/decision/decision_type.dart';
import 'package:pharos_ai_runtime/knowledge/department_fact_builder.dart';
import 'package:pharos_ai_runtime/knowledge/fact_extractor.dart';
import 'package:pharos_ai_runtime/knowledge/knowledge_graph_builder.dart';
import 'package:pharos_ai_runtime/models/conversation.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/operations/operational_snapshot.dart';
import 'package:pharos_ai_runtime/priorities/department_summary.dart';
import 'package:pharos_ai_runtime/priorities/executive_aggregator.dart';
import 'package:pharos_ai_runtime/priorities/executive_summary.dart';
import 'package:pharos_ai_runtime/prompts/department_prompt_builder.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_context.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_priority.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_step.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_step_status.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_type.dart';
import 'package:pharos_ai_runtime/workflow/planner/default_workflow_planner.dart';
import 'package:pharos_ai_runtime/workflow/registry/workflow_definition.dart';
import 'package:pharos_ai_runtime/workflow/registry/workflow_matcher.dart';
import 'package:pharos_ai_runtime/workflow/registry/workflow_registry.dart';
import 'package:pharos_ai_runtime/workflow/simulation/workflow_simulator.dart';

const _doubleLine = '══════════════════════════════';
const _defaultWorkspaceRoot = 'pharos-hq';
const _emptyWorkflowContext = WorkflowContext(
  company: {},
  market: {},
  finance: {},
);

/// One decision's execution preview, ready to render: which workflow it
/// matched, its execution groups (as step titles), and whether it is
/// blocked.
class _ExecutionPreview {
  const _ExecutionPreview({
    required this.definitionId,
    required this.groupTitles,
    required this.isBlocked,
  });

  final String definitionId;
  final List<List<String>> groupTitles;
  final bool isBlocked;
}

/// The Runtime's only known built-in workflow today: the roadmap's own
/// Launch Campaign example, matched against the same DecisionType the
/// Decision Engine's "Prepare launch campaign" rule produces. Additional
/// built-in workflows are future work — see the note in
/// lib/workflow/README.md about where canonical definitions should live.
WorkflowDefinition _launchCampaignDefinition() {
  WorkflowStep step(
    String id,
    String title, {
    List<String> dependsOn = const [],
  }) => WorkflowStep(
    id: id,
    title: title,
    description: '',
    status: WorkflowStepStatus.pending,
    dependsOn: dependsOn,
    metadata: const {},
  );

  return WorkflowDefinition(
    id: 'launch_campaign',
    type: WorkflowType.launchCampaign,
    title: 'Launch Campaign',
    description: 'Prepare and launch a marketing campaign.',
    supportedDecisionTypes: const [DecisionType.launch],
    defaultPriority: WorkflowPriority.high,
    steps: [
      step('analyze-market', 'Analyze Market'),
      step('analyze-budget', 'Analyze Budget'),
      step(
        'design-campaign',
        'Design Campaign',
        dependsOn: ['analyze-market', 'analyze-budget'],
      ),
      step(
        'generate-images',
        'Generate Images',
        dependsOn: ['design-campaign'],
      ),
      step(
        'generate-videos',
        'Generate Videos',
        dependsOn: ['design-campaign'],
      ),
      step(
        'publish',
        'Publish',
        dependsOn: ['generate-images', 'generate-videos'],
      ),
      step('measure', 'Measure', dependsOn: ['publish']),
    ],
    metadata: const {},
  );
}

/// Generates today's Executive Brief: Load HQ -> Company Documents ->
/// Fact Extraction -> Knowledge Graph -> Department Facts -> Operational
/// State -> Decision Engine -> Priority Engine -> Executive Aggregator ->
/// Workflow Planner -> Workflow Simulator -> LLM -> Executive Brief. The
/// Executive never sees departmental decisions independently, and now
/// sees not only what should happen but a deterministic preview of how
/// it would happen — without anything actually executing.
class DailyAgent extends Agent {
  DailyAgent({String? workspaceRoot})
    : _workspaceRoot =
          workspaceRoot ??
          Platform.environment['PHAROS_HQ_ROOT'] ??
          _defaultWorkspaceRoot;

  final String _workspaceRoot;

  @override
  String get id => 'daily';

  @override
  Future<Result> run(ExecutionContext context) async {
    const loader = CompanyLoader();
    const factExtractor = FactExtractor();
    const graphBuilder = KnowledgeGraphBuilder();
    const departmentFactBuilder = DepartmentFactBuilder();
    const decisionEngine = DecisionEngine();
    const executiveAggregator = ExecutiveAggregator();
    const promptBuilder = DepartmentPromptBuilder();

    final documents = await loader.load(_workspaceRoot);
    final facts = factExtractor.extract(documents);
    final graph = graphBuilder.build(facts);
    final departmentFactsList = departmentFactBuilder.buildAll(graph);

    final departmentSummaries = <DepartmentSummary>[];
    for (final departmentFacts in departmentFactsList) {
      final snapshot = OperationalSnapshot.build(
        departmentFacts: departmentFacts,
        graph: graph,
      );
      final decisions = decisionEngine.generate(snapshot);
      departmentSummaries.add(
        DepartmentSummary.build(snapshot: snapshot, decisions: decisions),
      );
    }

    final executiveSummary = executiveAggregator.aggregate(departmentSummaries);

    final prompt = promptBuilder.buildReport(
      summary: executiveSummary,
      currentDate: DateTime.now(),
    );

    final response = await context.modelProvider.generate(
      ModelRequest(
        conversation: Conversation(messages: [UserMessage(content: prompt)]),
      ),
    );

    final executionPreviews = _buildExecutionPreviews(executiveSummary);

    print(_doubleLine);
    print('PHAROS TODAY');
    print(_doubleLine);
    print('');
    print(response.text);
    print('');
    print(_renderBlockedItems(executiveSummary));
    print('');
    print(_renderObservabilityGaps(executiveSummary));
    print('');
    print(_renderExecutionPreviews(executionPreviews));

    return Result.success("Today's Executive Brief generated successfully.");
  }

  /// Plans and simulates a Workflow for each top company decision that
  /// matches a registered WorkflowDefinition. A decision with no
  /// matching workflow, or one whose plan fails validation, simply
  /// produces no preview — that is expected, not an error, since not
  /// every decision maps to a known workflow yet.
  List<_ExecutionPreview> _buildExecutionPreviews(ExecutiveSummary summary) {
    final registry = WorkflowRegistry()..register(_launchCampaignDefinition());
    final matcher = WorkflowMatcher(registry);
    final planner = DefaultWorkflowPlanner(matcher);
    const simulator = WorkflowSimulator();

    final previews = <_ExecutionPreview>[];

    for (final merged in summary.topDecisions) {
      final planningResult = planner.plan(
        merged.decision,
        _emptyWorkflowContext,
      );
      if (!planningResult.success || planningResult.workflow == null) {
        continue;
      }

      final simulationResult = simulator.simulate(planningResult.workflow!);
      if (!simulationResult.success || simulationResult.simulation == null) {
        continue;
      }

      final instance = planningResult.workflow!;
      final titlesById = {
        for (final step in instance.steps) step.id: step.title,
      };
      final simulation = simulationResult.simulation!;

      previews.add(
        _ExecutionPreview(
          definitionId: instance.definitionId,
          groupTitles: [
            for (final group in simulation.executionGroups)
              [for (final id in group) titlesById[id] ?? id],
          ],
          isBlocked: simulation.blockedSteps.isNotEmpty,
        ),
      );
    }

    return previews;
  }

  /// Deterministically rendered by the Runtime from the already-merged,
  /// already-ranked ExecutiveSummary — never left to the LLM. Blocked
  /// work never appears as a normal recommendation, so it is always
  /// rendered here instead.
  String _renderBlockedItems(ExecutiveSummary summary) {
    final buffer = StringBuffer()..writeln('Blocked Items');

    if (summary.blockedDecisions.isEmpty) {
      buffer.writeln('- None.');
    } else {
      for (final entry in summary.blockedDecisions) {
        final affects = entry.affects.map((d) => d.displayName).join(', ');
        final reasons = entry.decision.reasons
            .map((r) => r.statement)
            .join('; ');
        buffer.writeln('- ${entry.decision.title} ($affects) — $reasons.');
      }
    }

    return buffer.toString().trimRight();
  }

  /// Missing data is rendered as a dashboard of categories, never as
  /// "Connect X" recommendations — those are implementation details the
  /// Executive should never see.
  String _renderObservabilityGaps(ExecutiveSummary summary) {
    final buffer = StringBuffer()..writeln('Observability Gaps');

    if (summary.observabilityGaps.isEmpty) {
      buffer.writeln('- None.');
    } else {
      for (final gap in summary.observabilityGaps) {
        buffer.writeln('✗ $gap');
      }
    }

    return buffer.toString().trimRight();
  }

  /// The Executive sees not only what should happen, but a deterministic
  /// preview of how it would happen. No execution has occurred by the
  /// time this is printed — the preview is purely a simulation.
  String _renderExecutionPreviews(List<_ExecutionPreview> previews) {
    final buffer = StringBuffer()..writeln('Execution Preview');

    if (previews.isEmpty) {
      buffer.writeln('- None.');
    } else {
      for (final preview in previews) {
        buffer.writeln();
        buffer.writeln('Workflow: ${preview.definitionId}');
        buffer.writeln('Status: ${preview.isBlocked ? 'Blocked' : 'Ready'}');
        for (var i = 0; i < preview.groupTitles.length; i++) {
          buffer.writeln('Group ${i + 1}');
          for (final title in preview.groupTitles[i]) {
            buffer.writeln('✓ $title');
          }
        }
      }
      buffer.writeln();
      buffer.writeln('No execution has occurred.');
    }

    return buffer.toString().trimRight();
  }
}
