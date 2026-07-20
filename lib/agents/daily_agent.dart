import 'dart:io';

import 'package:pharos_ai_runtime/company/company_context_builder.dart';
import 'package:pharos_ai_runtime/company/company_loader.dart';
import 'package:pharos_ai_runtime/company/company_snapshot.dart';
import 'package:pharos_ai_runtime/company/company_snapshot_builder.dart';
import 'package:pharos_ai_runtime/core/agent.dart';
import 'package:pharos_ai_runtime/core/context.dart';
import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/models/conversation.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/prompts/daily_prompt_builder.dart';

const _doubleLine = '══════════════════════════════';
const _defaultWorkspaceRoot = 'pharos-hq';
const _workflowGoal = 'Generate the daily executive report.';

/// Generates the Executive Daily Report, grounded on the HQ Workspace:
/// Load HQ -> Company Context -> Company Snapshot -> Daily Prompt
/// Builder -> LLM -> Executive Report. The Daily Agent never assembles
/// prompts inline and never reasons over CompanyContext directly — only
/// the normalized, deterministic CompanySnapshot reaches the prompt.
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
    const snapshotBuilder = CompanySnapshotBuilder();
    const promptBuilder = DailyPromptBuilder();

    final documents = await loader.load(_workspaceRoot);
    final companyContext = contextBuilder.build(documents);
    final snapshot = snapshotBuilder.build(companyContext);

    final prompt = promptBuilder.build(
      snapshot: snapshot,
      currentDate: DateTime.now(),
      workflowGoal: _workflowGoal,
    );

    final response = await context.modelProvider.generate(
      ModelRequest(
        conversation: Conversation(messages: [UserMessage(content: prompt)]),
      ),
    );

    print(_doubleLine);
    print('PHAROS DAILY REPORT');
    print(_doubleLine);
    print('');
    print(response.text);
    print('');
    print(_renderDataSourcesUsed(snapshot));

    return Result.success('Daily report generated successfully.');
  }

  /// Deterministically rendered by the Runtime from the already-computed
  /// CompanySnapshot — never left to the LLM, since discovering which
  /// sources contributed is exactly the kind of inference the LLM must
  /// never perform.
  String _renderDataSourcesUsed(CompanySnapshot snapshot) {
    final buffer = StringBuffer()..writeln('Data Sources Used');

    for (final category in snapshot.knownData) {
      buffer.writeln('✓ $category');
    }

    for (final category in snapshot.missingData) {
      buffer.writeln('✗ $category');
    }

    return buffer.toString().trimRight();
  }
}
