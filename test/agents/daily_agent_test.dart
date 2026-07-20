import 'dart:async';
import 'dart:io';

import 'package:pharos_ai_runtime/agents/daily_agent.dart';
import 'package:pharos_ai_runtime/core/context.dart';
import 'package:pharos_ai_runtime/core/job.dart';
import 'package:pharos_ai_runtime/models/conversation.dart';
import 'package:pharos_ai_runtime/models/model_provider.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/models/model_response.dart';
import 'package:test/test.dart';

class _SpyModelProvider extends ModelProvider {
  ModelRequest? capturedRequest;
  ModelResponse response = const ModelResponse(text: 'Executive report body.');

  @override
  Future<ModelResponse> generate(ModelRequest request) async {
    capturedRequest = request;

    return response;
  }
}

ExecutionContext _context(ModelProvider modelProvider) => ExecutionContext(
  sessionId: 'session-1',
  startedAt: DateTime(2024, 1, 1),
  environment: 'test',
  job: Job(id: 'job-1', agentId: 'daily', createdAt: DateTime(2024, 1, 1)),
  modelProvider: modelProvider,
);

Future<List<String>> _capturePrintedLines(Future<void> Function() body) async {
  final output = <String>[];

  await runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => output.add(line),
    ),
  );

  return output;
}

void main() {
  late Directory workspace;

  setUp(() {
    workspace = Directory.systemTemp.createTempSync('daily_agent_test_');
  });

  tearDown(() {
    if (workspace.existsSync()) {
      workspace.deleteSync(recursive: true);
    }
  });

  test('id is "daily"', () {
    final agent = DailyAgent(workspaceRoot: workspace.path);

    expect(agent.id, 'daily');
  });

  test('run() sends exactly one request to the ModelProvider', () async {
    final modelProvider = _SpyModelProvider();
    final agent = DailyAgent(workspaceRoot: workspace.path);

    await agent.run(_context(modelProvider));

    expect(modelProvider.capturedRequest, isNotNull);
  });

  test('run() uses CompanySnapshot rather than CompanyContext directly: the '
      'sent prompt is shaped like a DailyPromptBuilder prompt (Company '
      'Snapshot, Known Data, Missing Data, Risks), not a raw Company '
      'Context dump', () async {
    final companyDir = Directory('${workspace.path}/company')..createSync();
    File(
      '${companyDir.path}/overview.md',
    ).writeAsStringSync('# Overview\n\nWe build developer tools.');

    final modelProvider = _SpyModelProvider();
    final agent = DailyAgent(workspaceRoot: workspace.path);

    await agent.run(_context(modelProvider));

    final prompt = modelProvider.capturedRequest!.conversation.messages
        .whereType<UserMessage>()
        .single
        .content;

    expect(prompt, contains('Company Snapshot:'));
    expect(prompt, contains('Known Data:'));
    expect(prompt, contains('Missing Data:'));
    expect(prompt, contains('Risks:'));
    expect(prompt, contains('Recommendations Input:'));
    expect(prompt, contains('We build developer tools.'));
    // The old CompanyContext-style prompt never mentioned a workflow
    // goal or distinguished Known/Unknown/Recommendation.
    expect(prompt, contains('Workflow goal:'));
  });

  test('run() prompt contains the hallucination prevention rules', () async {
    final modelProvider = _SpyModelProvider();
    final agent = DailyAgent(workspaceRoot: workspace.path);

    await agent.run(_context(modelProvider));

    final prompt = modelProvider.capturedRequest!.conversation.messages
        .whereType<UserMessage>()
        .single
        .content;

    expect(prompt, contains('Never invent company facts'));
    expect(prompt, contains('Never invent KPIs'));
    expect(prompt, contains('Never invent campaigns'));
    expect(prompt, contains('Never invent analytics'));
    expect(prompt, contains('Never invent revenue'));
    expect(prompt, contains('unavailable'));
    expect(prompt, contains('Known'));
    expect(prompt, contains('Unknown'));
    expect(prompt, contains('Recommendation'));
  });

  test('run() prints PHAROS DAILY REPORT, the generated Executive Report, '
      'and a Data Sources Used section', () async {
    final companyDir = Directory('${workspace.path}/company')..createSync();
    File(
      '${companyDir.path}/overview.md',
    ).writeAsStringSync('Overview content.');

    final modelProvider = _SpyModelProvider()
      ..response = const ModelResponse(
        text: 'Executive Summary\nEverything looks stable.',
      );
    final agent = DailyAgent(workspaceRoot: workspace.path);

    final output = await _capturePrintedLines(
      () => agent.run(_context(modelProvider)),
    );
    final report = output.join('\n');

    expect(report, contains('PHAROS DAILY REPORT'));
    expect(report, contains('Everything looks stable.'));
    expect(report, contains('Data Sources Used'));
    expect(report, contains('✓ Company'));
    expect(report, contains('✗ CRM'));
  });

  test('run() returns a success Result', () async {
    final modelProvider = _SpyModelProvider();
    final agent = DailyAgent(workspaceRoot: workspace.path);

    final result = await agent.run(_context(modelProvider));

    expect(result.success, isTrue);
  });
}
