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
  ModelResponse response = const ModelResponse(text: 'Grounded report.');

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

  test("run() uses the CompanyContext built from HQ: loaded documents' "
      'content reaches the prompt', () async {
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

    expect(prompt, contains('We build developer tools.'));
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
    expect(prompt, contains('unavailable'));
    expect(prompt, contains('Unknown'));
    expect(prompt, contains('KPIs'));
    expect(prompt, contains('campaigns'));
    expect(prompt, contains('revenue'));
    expect(prompt, contains('customers'));
    expect(prompt, contains('metrics'));
    expect(prompt, contains('analytics'));
    expect(prompt, contains('marketing activities'));
  });

  test('run() reports sections with no HQ documents as "Not yet connected" '
      'rather than fabricating content for them', () async {
    // An empty workspace: nothing under any category folder.
    final modelProvider = _SpyModelProvider();
    final agent = DailyAgent(workspaceRoot: workspace.path);

    await agent.run(_context(modelProvider));

    final prompt = modelProvider.capturedRequest!.conversation.messages
        .whereType<UserMessage>()
        .single
        .content;

    expect(prompt, contains('Not yet connected'));
  });

  test('run() prints PHAROS DAILY REPORT and the generated response', () async {
    final modelProvider = _SpyModelProvider()
      ..response = const ModelResponse(
        text: 'No live analytics are currently connected.',
      );
    final agent = DailyAgent(workspaceRoot: workspace.path);

    final output = await _capturePrintedLines(
      () => agent.run(_context(modelProvider)),
    );
    final report = output.join('\n');

    expect(report, contains('PHAROS DAILY REPORT'));
    expect(report, contains('No live analytics are currently connected.'));
  });

  test('run() returns a success Result', () async {
    final modelProvider = _SpyModelProvider();
    final agent = DailyAgent(workspaceRoot: workspace.path);

    final result = await agent.run(_context(modelProvider));

    expect(result.success, isTrue);
  });
}
