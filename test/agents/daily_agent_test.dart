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
    text: 'Company health is strong today.',
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

  test('run() sends a prompt grounded in the aggregated Executive Summary, '
      'never raw HQ markdown or a filesystem path', () async {
    final productsDir = Directory('${workspace.path}/products')..createSync();
    File('${productsDir.path}/petsupo.md').writeAsStringSync(
      '# Petsupo\n\n'
      'This exact raw markdown sentence must never reach the LLM.',
    );
    final assetsDir = Directory('${workspace.path}/assets')..createSync();
    File(
      '${assetsDir.path}/brand-kit.md',
    ).writeAsStringSync('Brand guidelines.');
    File('${assetsDir.path}/hero-video.md').writeAsStringSync('Hero video.');

    final modelProvider = _SpyModelProvider();
    final agent = DailyAgent(workspaceRoot: workspace.path);

    await agent.run(_context(modelProvider));

    final prompt = modelProvider.capturedRequest!.conversation.messages
        .whereType<UserMessage>()
        .single
        .content;

    expect(prompt, contains('Executive Summary:'));
    expect(prompt, contains('Company Health:'));
    expect(prompt, contains('Department Summaries:'));
    expect(prompt, contains('Health Scores:'));
    expect(prompt, contains('Top Decisions:'));
    expect(prompt, contains('Prepare launch campaign'));
    expect(prompt, contains('Affects:'));
    expect(
      prompt,
      isNot(
        contains('This exact raw markdown sentence must never reach the LLM'),
      ),
    );
    expect(prompt, isNot(contains('products/petsupo')));
    expect(prompt, isNot(contains('.md')));
  });

  test(
    'run() never lets the LLM calculate its own priority or health score',
    () async {
      final modelProvider = _SpyModelProvider();
      final agent = DailyAgent(workspaceRoot: workspace.path);

      await agent.run(_context(modelProvider));

      final prompt = modelProvider.capturedRequest!.conversation.messages
          .whereType<UserMessage>()
          .single
          .content;

      expect(prompt, contains('not the decision maker'));
      expect(
        prompt,
        contains('do not calculate your own priority or health score'),
      );
    },
  );

  test('run() prints PHAROS TODAY, the generated Executive Brief, and '
      'Runtime-rendered Blocked Items and Observability Gaps as a '
      'dashboard — never as "Connect X" recommendations', () async {
    final websitesDir = Directory('${workspace.path}/websites')..createSync();
    File(
      '${websitesDir.path}/petsupo-com.md',
    ).writeAsStringSync('Marketing website.');
    final assetsDir = Directory('${workspace.path}/assets')..createSync();
    File(
      '${assetsDir.path}/brand-kit.md',
    ).writeAsStringSync('Brand guidelines.');
    File('${assetsDir.path}/hero-video.md').writeAsStringSync('Hero video.');

    final modelProvider = _SpyModelProvider()
      ..response = const ModelResponse(text: 'Company health is strong.');
    final agent = DailyAgent(workspaceRoot: workspace.path);

    final output = await _capturePrintedLines(
      () => agent.run(_context(modelProvider)),
    );
    final report = output.join('\n');

    expect(report, contains('PHAROS TODAY'));
    expect(report, contains('Company health is strong.'));
    expect(report, contains('Blocked Items'));
    expect(report, contains('Observability Gaps'));
    expect(report, contains('Campaign Optimization'));
    expect(report, isNot(contains('Connect reachable')));
    expect(report, isNot(contains('Missing Operational Data')));
  });

  test('run() integrates a deterministic Execution Preview into the '
      'printed Executive Brief for a decision matching the built-in '
      'launch_campaign workflow, without executing anything', () async {
    final productsDir = Directory('${workspace.path}/products')..createSync();
    File(
      '${productsDir.path}/petsupo.md',
    ).writeAsStringSync('A pet care marketplace.');
    final assetsDir = Directory('${workspace.path}/assets')..createSync();
    File(
      '${assetsDir.path}/brand-kit.md',
    ).writeAsStringSync('Brand guidelines.');
    File('${assetsDir.path}/hero-video.md').writeAsStringSync('Hero video.');

    final modelProvider = _SpyModelProvider();
    final agent = DailyAgent(workspaceRoot: workspace.path);

    final output = await _capturePrintedLines(
      () => agent.run(_context(modelProvider)),
    );
    final report = output.join('\n');

    expect(report, contains('Execution Preview'));
    expect(report, contains('Workflow: launch_campaign'));
    expect(report, contains('Status: Ready'));
    expect(report, contains('Group 1'));
    expect(report, contains('✓ Analyze Market'));
    expect(report, contains('✓ Analyze Budget'));
    expect(report, contains('Group 5'));
    expect(report, contains('✓ Measure'));
    expect(report, contains('No execution has occurred.'));
  });

  test('run() returns a success Result', () async {
    final modelProvider = _SpyModelProvider();
    final agent = DailyAgent(workspaceRoot: workspace.path);

    final result = await agent.run(_context(modelProvider));

    expect(result.success, isTrue);
  });
}
