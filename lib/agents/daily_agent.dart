import 'dart:io';

import 'package:pharos_ai_runtime/company/company_loader.dart';
import 'package:pharos_ai_runtime/core/agent.dart';
import 'package:pharos_ai_runtime/core/context.dart';
import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/decision/decision_engine.dart';
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

const _doubleLine = '══════════════════════════════';
const _defaultWorkspaceRoot = 'pharos-hq';

/// Generates today's Executive Brief: Load HQ -> Company Documents ->
/// Fact Extraction -> Knowledge Graph -> Department Facts -> Operational
/// State -> Decision Engine -> Priority Engine -> Executive Aggregator ->
/// LLM -> Executive Brief. The Executive never sees departmental
/// decisions independently: it receives only the highest-value,
/// deduplicated, ranked company decisions the Runtime already computed.
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

    print(_doubleLine);
    print('PHAROS TODAY');
    print(_doubleLine);
    print('');
    print(response.text);
    print('');
    print(_renderBlockedItems(executiveSummary));
    print('');
    print(_renderObservabilityGaps(executiveSummary));

    return Result.success("Today's Executive Brief generated successfully.");
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
}
