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
  ModelResponse response = const ModelResponse(
    text: "Today's Marketing Priorities\nPublish content.",
  );

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

  test('run() sends exactly one request to the ModelProvider for the whole '
      'Company Plan', () async {
    final modelProvider = _SpyModelProvider();
    final agent = DailyAgent(workspaceRoot: workspace.path);

    await agent.run(_context(modelProvider));

    expect(modelProvider.capturedRequest, isNotNull);
  });

  test('run() sends a prompt grounded per department, not a generic company '
      'summary', () async {
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

    expect(prompt, contains('Executive Snapshot:'));
    expect(prompt, contains('Engineering Snapshot:'));
    expect(prompt, contains('Marketing Snapshot:'));
    expect(prompt, contains('Sales Snapshot:'));
    expect(prompt, contains('Operations Snapshot:'));
    expect(prompt, contains('Finance Snapshot:'));
    expect(prompt, contains("Today's Executive Priorities"));
    expect(prompt, contains("Today's Finance Priorities"));
    expect(prompt, contains('We build developer tools.'));
  });

  test('run() prompt contains hallucination-prevention rules', () async {
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
  });

  test('run() prints PHAROS TODAY, the generated Company Plan, and '
      'Runtime-rendered Blocked Items, Missing Data, and Recommended Next '
      'Connections sections', () async {
    final companyDir = Directory('${workspace.path}/company')..createSync();
    File(
      '${companyDir.path}/overview.md',
    ).writeAsStringSync('Overview content.');

    final modelProvider = _SpyModelProvider()
      ..response = const ModelResponse(
        text: "Today's Executive Priorities\nStabilize the roadmap.",
      );
    final agent = DailyAgent(workspaceRoot: workspace.path);

    final output = await _capturePrintedLines(
      () => agent.run(_context(modelProvider)),
    );
    final report = output.join('\n');

    expect(report, contains('PHAROS TODAY'));
    expect(report, contains('Stabilize the roadmap.'));
    expect(report, contains('Blocked Items'));
    expect(report, contains('Missing Data'));
    expect(report, contains('Recommended Next Connections'));
  });

  test('run() returns a success Result', () async {
    final modelProvider = _SpyModelProvider();
    final agent = DailyAgent(workspaceRoot: workspace.path);

    final result = await agent.run(_context(modelProvider));

    expect(result.success, isTrue);
  });
}
