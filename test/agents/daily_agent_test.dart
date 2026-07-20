import 'dart:async';

import 'package:pharos_ai_runtime/agents/daily_agent.dart';
import 'package:pharos_ai_runtime/core/context.dart';
import 'package:pharos_ai_runtime/core/job.dart';
import 'package:pharos_ai_runtime/models/conversation.dart';
import 'package:pharos_ai_runtime/models/model_provider.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/models/model_response.dart';
import 'package:test/test.dart';

class _SpyModelProvider extends ModelProvider {
  final List<ModelRequest> capturedRequests = [];
  int callCount = 0;

  @override
  Future<ModelResponse> generate(ModelRequest request) async {
    callCount++;
    capturedRequests.add(request);

    return ModelResponse(text: 'Generated marketing copy #$callCount');
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
  test('id is "daily"', () {
    final agent = DailyAgent();

    expect(agent.id, 'daily');
  });

  test('run() sends exactly one request per enabled product', () async {
    final modelProvider = _SpyModelProvider();
    final agent = DailyAgent();

    await agent.run(_context(modelProvider));

    expect(modelProvider.callCount, 5);
  });

  test(
    'run() processes products in registry order, one request each',
    () async {
      final modelProvider = _SpyModelProvider();
      final agent = DailyAgent();

      await agent.run(_context(modelProvider));

      final userMessages = modelProvider.capturedRequests
          .map(
            (r) =>
                r.conversation.messages.whereType<UserMessage>().single.content,
          )
          .toList();

      expect(userMessages[0], contains('Petsupo'));
      expect(userMessages[1], contains('DevAudit'));
      expect(userMessages[2], contains('HubMonix'));
      expect(userMessages[3], contains('devclean'));
      expect(userMessages[4], contains('leadforge'));
    },
  );

  test('run() includes every enabled product\'s prompt fields (description, '
      'target audience, value proposition)', () async {
    final modelProvider = _SpyModelProvider();
    final agent = DailyAgent();

    await agent.run(_context(modelProvider));

    final petsupoPrompt = modelProvider
        .capturedRequests[0]
        .conversation
        .messages
        .whereType<UserMessage>()
        .single
        .content;

    expect(petsupoPrompt, contains('Petsupo'));
    expect(petsupoPrompt, contains('pet care'));
    expect(petsupoPrompt, contains('Pet owners'));
    expect(petsupoPrompt, contains('Book vetted pet care services'));
  });

  test('run() prints PHAROS DAILY REPORT and a section for every enabled '
      "product, containing that product's generated response", () async {
    final modelProvider = _SpyModelProvider();
    final agent = DailyAgent();

    final output = await _capturePrintedLines(
      () => agent.run(_context(modelProvider)),
    );
    final report = output.join('\n');

    expect(report, contains('PHAROS DAILY REPORT'));
    expect(report, contains('Petsupo'));
    expect(report, contains('DevAudit'));
    expect(report, contains('HubMonix'));
    expect(report, contains('devclean'));
    expect(report, contains('leadforge'));
    expect(report, contains('Generated marketing copy #1'));
    expect(report, contains('Generated marketing copy #2'));
    expect(report, contains('Generated marketing copy #3'));
    expect(report, contains('Generated marketing copy #4'));
    expect(report, contains('Generated marketing copy #5'));
  });

  test('run() returns a success Result', () async {
    final modelProvider = _SpyModelProvider();
    final agent = DailyAgent();

    final result = await agent.run(_context(modelProvider));

    expect(result.success, isTrue);
  });
}
