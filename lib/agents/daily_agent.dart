import 'dart:io';

import 'package:pharos_ai_runtime/company/company_context.dart';
import 'package:pharos_ai_runtime/company/company_context_builder.dart';
import 'package:pharos_ai_runtime/company/company_loader.dart';
import 'package:pharos_ai_runtime/core/agent.dart';
import 'package:pharos_ai_runtime/core/context.dart';
import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/models/conversation.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';

const _doubleLine = '══════════════════════════════';
const _defaultWorkspaceRoot = 'pharos-hq';

/// Generates the daily company report, grounded on the HQ Workspace:
/// Load HQ -> Build Company Context -> Build Daily Prompt -> Call LLM.
/// The Runtime never assumes company information is embedded inside
/// prompts — everything the LLM is told about the company comes from
/// documents actually found under the HQ workspace root.
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
    const builder = CompanyContextBuilder();

    final documents = await loader.load(_workspaceRoot);
    final companyContext = builder.build(documents);

    final response = await context.modelProvider.generate(
      ModelRequest(
        conversation: Conversation(
          messages: [UserMessage(content: _buildPrompt(companyContext))],
        ),
      ),
    );

    print(_doubleLine);
    print('PHAROS DAILY REPORT');
    print(_doubleLine);
    print('');
    print(response.text);

    return Result.success('Daily report generated successfully.');
  }

  String _buildPrompt(CompanyContext context) {
    final buffer = StringBuffer()
      ..writeln('You are writing today\'s internal Pharos company report.')
      ..writeln()
      ..writeln('Rules:')
      ..writeln('- Never invent company facts.')
      ..writeln('- Use only the Company Context supplied below.')
      ..writeln(
        '- If information is unavailable, explicitly state that it is '
        'unavailable.',
      )
      ..writeln(
        '- Never fabricate KPIs, campaigns, revenue, customers, metrics, '
        'analytics, or marketing activities.',
      )
      ..writeln(
        '- Prefer "Unknown", "Unavailable", or "Not yet connected" over '
        'fabricated information.',
      )
      ..writeln()
      ..writeln('Company Context:')
      ..write(_renderSection('Company', context.company))
      ..write(_renderSection('Knowledge', context.knowledge))
      ..write(_renderSection('Products', context.products))
      ..write(_renderSection('Assets', context.assets))
      ..write(_renderSection('Services', context.services))
      ..write(_renderSection('Websites', context.websites))
      ..write(_renderSection('Social', context.social))
      ..write(_renderSection('Analytics', context.analytics));

    return buffer.toString();
  }

  String _renderSection(String title, List<String> entries) {
    final buffer = StringBuffer()..writeln('$title:');

    if (entries.isEmpty) {
      buffer.writeln('- Not yet connected.');
    } else {
      for (final entry in entries) {
        buffer.writeln('- $entry');
      }
    }

    return buffer.toString();
  }
}
