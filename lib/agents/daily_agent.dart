import 'dart:io';

import 'package:pharos_ai_runtime/company/company_loader.dart';
import 'package:pharos_ai_runtime/core/agent.dart';
import 'package:pharos_ai_runtime/core/context.dart';
import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/knowledge/department_fact_builder.dart';
import 'package:pharos_ai_runtime/knowledge/fact_extractor.dart';
import 'package:pharos_ai_runtime/knowledge/knowledge_graph_builder.dart';
import 'package:pharos_ai_runtime/models/conversation.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/operations/operational_snapshot.dart';
import 'package:pharos_ai_runtime/prompts/department_prompt_builder.dart';

const _doubleLine = '══════════════════════════════';
const _defaultWorkspaceRoot = 'pharos-hq';

/// Generates today's Executive Plan, grounded exclusively on Operational
/// State: Load HQ -> Company Documents -> Fact Extraction -> Knowledge
/// Graph -> Department Facts -> Operational State Builder -> Operational
/// Snapshot -> Decision Gate -> Department Prompt Builder -> LLM ->
/// Executive Plan. Facts alone never generate recommendations: only
/// entities the Decision Gate marks as having sufficient evidence may
/// receive an action-level recommendation from the LLM.
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
    const promptBuilder = DepartmentPromptBuilder();

    final documents = await loader.load(_workspaceRoot);
    final facts = factExtractor.extract(documents);
    final graph = graphBuilder.build(facts);
    final departmentFacts = departmentFactBuilder.buildAll(graph);
    final operationalSnapshots = [
      for (final facts in departmentFacts)
        OperationalSnapshot.build(departmentFacts: facts, graph: graph),
    ];

    final prompt = promptBuilder.buildReport(
      operationalSnapshots: operationalSnapshots,
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
    print(_renderBlockedItems(operationalSnapshots));
    print('');
    print(_renderMissingOperationalData(operationalSnapshots));
    print('');
    print(_renderRecommendedNextConnections(operationalSnapshots));

    return Result.success("Today's Executive Plan generated successfully.");
  }

  /// Deterministically rendered by the Runtime from the already-computed
  /// OperationalSnapshots — never left to the LLM, since deciding which
  /// entities lack sufficient evidence is exactly the kind of inference
  /// the LLM must never perform.
  String _renderBlockedItems(List<OperationalSnapshot> operationalSnapshots) {
    final buffer = StringBuffer()..writeln('Blocked Items');
    final items = _dedupe([
      for (final snapshot in operationalSnapshots)
        for (final blocked in snapshot.blocked)
          '${snapshot.department.displayName} cannot recommend action on '
              '${blocked.state.name} (${blocked.state.factType.displayName}) '
              '— missing: ${blocked.missingSignals.join(', ')}.',
    ]);

    if (items.isEmpty) {
      buffer.writeln('- None.');
    } else {
      for (final item in items) {
        buffer.writeln('- $item');
      }
    }

    return buffer.toString().trimRight();
  }

  String _renderMissingOperationalData(
    List<OperationalSnapshot> operationalSnapshots,
  ) {
    final buffer = StringBuffer()..writeln('Missing Operational Data');
    final missing = _dedupe([
      for (final snapshot in operationalSnapshots)
        ...snapshot.missingOperationalData,
    ]);

    if (missing.isEmpty) {
      buffer.writeln('- None.');
    } else {
      for (final entry in missing) {
        buffer.writeln('✗ $entry');
      }
    }

    return buffer.toString().trimRight();
  }

  String _renderRecommendedNextConnections(
    List<OperationalSnapshot> operationalSnapshots,
  ) {
    final buffer = StringBuffer()..writeln('Recommended Next Connections');
    final missing = _dedupe([
      for (final snapshot in operationalSnapshots)
        ...snapshot.missingOperationalData,
    ]);

    if (missing.isEmpty) {
      buffer.writeln('- None.');
    } else {
      for (final entry in missing) {
        buffer.writeln('- Connect $entry');
      }
    }

    return buffer.toString().trimRight();
  }

  List<String> _dedupe(List<String> entries) {
    final seen = <String>{};
    return [
      for (final entry in entries)
        if (seen.add(entry)) entry,
    ];
  }
}
