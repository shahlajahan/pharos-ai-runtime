import 'dart:async';

import 'package:pharos_ai_runtime/agents/marketing_agent.dart';
import 'package:pharos_ai_runtime/core/context.dart';
import 'package:pharos_ai_runtime/core/job.dart';
import 'package:pharos_ai_runtime/models/conversation.dart';
import 'package:pharos_ai_runtime/models/model_provider.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/models/model_response.dart';
import 'package:test/test.dart';

class _SpyModelProvider extends ModelProvider {
  ModelRequest? capturedRequest;
  ModelResponse response = const ModelResponse(text: 'Hello from the model!');

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
  job: Job(id: 'job-1', agentId: 'marketing', createdAt: DateTime(2024, 1, 1)),
  modelProvider: modelProvider,
);

void main() {
  test('MarketingAgent sends "Say hello from Pharos AI Runtime." through the '
      "context's ModelProvider", () async {
    final modelProvider = _SpyModelProvider();
    final agent = MarketingAgent();

    await agent.run(_context(modelProvider));

    final userMessage = modelProvider.capturedRequest!.conversation.messages
        .whereType<UserMessage>()
        .single;
    expect(userMessage.content, 'Say hello from Pharos AI Runtime.');
  });

  test("MarketingAgent prints the ModelProvider's response text", () async {
    final modelProvider = _SpyModelProvider()
      ..response = const ModelResponse(text: 'Hello from Pharos AI Runtime!');
    final agent = MarketingAgent();
    final output = <String>[];

    await runZoned(
      () => agent.run(_context(modelProvider)),
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) => output.add(line),
      ),
    );

    expect(
      output.any((line) => line.contains('Hello from Pharos AI Runtime!')),
      isTrue,
    );
  });

  test('MarketingAgent returns a success Result', () async {
    final modelProvider = _SpyModelProvider();
    final agent = MarketingAgent();

    final result = await agent.run(_context(modelProvider));

    expect(result.success, isTrue);
  });
}
