import 'dart:io';

import 'package:pharos_ai_runtime/company/company_loader.dart';
import 'package:pharos_ai_runtime/company/department_facts.dart';
import 'package:pharos_ai_runtime/core/agent.dart';
import 'package:pharos_ai_runtime/core/context.dart';
import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/knowledge/department_fact_builder.dart';
import 'package:pharos_ai_runtime/knowledge/fact_extractor.dart';
import 'package:pharos_ai_runtime/knowledge/knowledge_graph_builder.dart';
import 'package:pharos_ai_runtime/models/conversation.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/prompts/department_prompt_builder.dart';

const _doubleLine = '══════════════════════════════';
const _defaultWorkspaceRoot = 'pharos-hq';

/// Generates today's Executive Plan, grounded exclusively on the Company
/// Knowledge Graph: Load HQ -> Company Documents -> Fact Extraction ->
/// Knowledge Graph -> Department Facts -> Department Prompt Builder ->
/// LLM -> Executive Plan. FactExtractor is the only place HQ document
/// content is ever read — the Daily Agent never inspects markdown
/// directly, and only already-computed DepartmentFacts reach the prompt.
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

    final prompt = promptBuilder.buildReport(
      departmentFacts: departmentFacts,
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
    print(_renderBlockedItems(departmentFacts));
    print('');
    print(_renderMissingFacts(departmentFacts));
    print('');
    print(_renderRecommendedNextConnections(departmentFacts));

    return Result.success("Today's Executive Plan generated successfully.");
  }

  /// Deterministically rendered by the Runtime from the already-computed
  /// DepartmentFacts — never left to the LLM, since identifying blockers
  /// and gaps is exactly the kind of inference the LLM must never
  /// perform.
  String _renderBlockedItems(List<DepartmentFacts> departmentFacts) {
    final buffer = StringBuffer()..writeln('Blocked Items');
    final items = _dedupe([
      for (final facts in departmentFacts)
        for (final type in facts.missingTypes)
          '${facts.department.displayName} cannot fully plan today '
              'without ${type.displayName} facts — none are known yet.',
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

  String _renderMissingFacts(List<DepartmentFacts> departmentFacts) {
    final buffer = StringBuffer()..writeln('Missing Facts');
    final missing = _dedupe([
      for (final facts in departmentFacts)
        for (final type in facts.missingTypes) type.displayName,
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
    List<DepartmentFacts> departmentFacts,
  ) {
    final buffer = StringBuffer()..writeln('Recommended Next Connections');
    final missing = _dedupe([
      for (final facts in departmentFacts)
        for (final type in facts.missingTypes) type.displayName,
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
