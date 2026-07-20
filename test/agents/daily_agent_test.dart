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

  test('run() sends exactly one request to the ModelProvider', () async {
    final modelProvider = _SpyModelProvider();
    final agent = DailyAgent(workspaceRoot: workspace.path);

    await agent.run(_context(modelProvider));

    expect(modelProvider.capturedRequest, isNotNull);
  });

  test('run() sends a prompt grounded in Operational State, marking an '
      'existence-only fact as allowed for action and a Website as blocked '
      'pending readiness evidence', () async {
    final productsDir = Directory('${workspace.path}/products')..createSync();
    File(
      '${productsDir.path}/petsupo.md',
    ).writeAsStringSync('# Petsupo\n\nA pet care marketplace.');
    final websitesDir = Directory('${workspace.path}/websites')..createSync();
    File(
      '${websitesDir.path}/petsupo-com.md',
    ).writeAsStringSync('Marketing website.');

    final modelProvider = _SpyModelProvider();
    final agent = DailyAgent(workspaceRoot: workspace.path);

    await agent.run(_context(modelProvider));

    final prompt = modelProvider.capturedRequest!.conversation.messages
        .whereType<UserMessage>()
        .single
        .content;

    expect(prompt, contains('Marketing Operational State:'));
    expect(prompt, contains('reachable=Unknown'));
    expect(prompt, contains('Allowed for action recommendations: petsupo'));
    expect(prompt, contains('Blocked (insufficient evidence): petsupo-com'));
  });

  test(
    'run() never sends raw HQ markdown or a filesystem path to the LLM',
    () async {
      final productsDir = Directory('${workspace.path}/products')..createSync();
      File('${productsDir.path}/petsupo.md').writeAsStringSync(
        '# Petsupo\n\n'
        'This exact raw markdown sentence must never reach the LLM.',
      );

      final modelProvider = _SpyModelProvider();
      final agent = DailyAgent(workspaceRoot: workspace.path);

      await agent.run(_context(modelProvider));

      final prompt = modelProvider.capturedRequest!.conversation.messages
          .whereType<UserMessage>()
          .single
          .content;

      expect(
        prompt,
        isNot(
          contains('This exact raw markdown sentence must never reach the LLM'),
        ),
      );
      expect(prompt, isNot(contains('products/petsupo')));
      expect(prompt, isNot(contains('.md')));
    },
  );

  test('run() prints PHAROS TODAY, the generated Executive Plan, and '
      'Runtime-rendered Blocked Items, Missing Operational Data, and '
      'Recommended Next Connections sections', () async {
    final websitesDir = Directory('${workspace.path}/websites')..createSync();
    File(
      '${websitesDir.path}/petsupo-com.md',
    ).writeAsStringSync('Marketing website.');

    final modelProvider = _SpyModelProvider()
      ..response = const ModelResponse(
        text: "Today's Marketing Priorities\nImprove observability.",
      );
    final agent = DailyAgent(workspaceRoot: workspace.path);

    final output = await _capturePrintedLines(
      () => agent.run(_context(modelProvider)),
    );
    final report = output.join('\n');

    expect(report, contains('PHAROS TODAY'));
    expect(report, contains('Improve observability.'));
    expect(report, contains('Blocked Items'));
    expect(report, contains('Missing Operational Data'));
    expect(report, contains('Recommended Next Connections'));
    expect(report, contains('cannot recommend action on petsupo-com'));
  });

  test('run() returns a success Result', () async {
    final modelProvider = _SpyModelProvider();
    final agent = DailyAgent(workspaceRoot: workspace.path);

    final result = await agent.run(_context(modelProvider));

    expect(result.success, isTrue);
  });
}
