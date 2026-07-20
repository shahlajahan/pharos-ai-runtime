import 'dart:io';

import 'package:pharos_ai_runtime/company/company_context_builder.dart';
import 'package:pharos_ai_runtime/company/company_loader.dart';
import 'package:pharos_ai_runtime/company/department_context_builder.dart';
import 'package:pharos_ai_runtime/company/department_snapshot.dart';
import 'package:pharos_ai_runtime/core/agent.dart';
import 'package:pharos_ai_runtime/core/context.dart';
import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/models/conversation.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/prompts/department_prompt_builder.dart';

const _doubleLine = '══════════════════════════════';
const _defaultWorkspaceRoot = 'pharos-hq';

/// Generates today's department-based Company Plan, grounded on the HQ
/// Workspace: Load HQ -> Company Context -> Department Context Builder ->
/// Department Snapshots -> Department Prompt Builder -> LLM -> Today's
/// Company Plan. The Daily Agent never decides department scope itself
/// and never assembles prompts inline — only already-computed
/// DepartmentSnapshots reach the prompt, and only the LLM writes each
/// department's priorities.
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
    const contextBuilder = CompanyContextBuilder();
    const departmentContextBuilder = DepartmentContextBuilder();
    const promptBuilder = DepartmentPromptBuilder();

    final documents = await loader.load(_workspaceRoot);
    final companyContext = contextBuilder.build(documents);
    final departmentContexts = departmentContextBuilder.buildAll(
      companyContext,
    );
    final snapshots = [
      for (final departmentContext in departmentContexts)
        DepartmentSnapshot.fromContext(departmentContext),
    ];

    final prompt = promptBuilder.buildReport(
      snapshots: snapshots,
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
    print(_renderBlockedItems(snapshots));
    print('');
    print(_renderMissingData(snapshots));
    print('');
    print(_renderRecommendedNextConnections(snapshots));

    return Result.success("Today's Company Plan generated successfully.");
  }

  /// Deterministically rendered by the Runtime from the already-computed
  /// DepartmentSnapshots — never left to the LLM, since identifying
  /// blockers and gaps is exactly the kind of inference the LLM must
  /// never perform.
  String _renderBlockedItems(List<DepartmentSnapshot> snapshots) {
    final buffer = StringBuffer()..writeln('Blocked Items');
    final items = _dedupe([
      for (final snapshot in snapshots) ...snapshot.blockedItems,
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

  String _renderMissingData(List<DepartmentSnapshot> snapshots) {
    final buffer = StringBuffer()..writeln('Missing Data');
    final missing = _dedupe([
      for (final snapshot in snapshots) ...snapshot.missingData,
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

  String _renderRecommendedNextConnections(List<DepartmentSnapshot> snapshots) {
    final buffer = StringBuffer()..writeln('Recommended Next Connections');
    final missing = _dedupe([
      for (final snapshot in snapshots) ...snapshot.missingData,
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
