import 'dart:convert';

import 'package:pharos_ai_runtime/models/http_openai_client.dart';
import 'package:pharos_ai_runtime/models/model_config.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/models/openai_config.dart';
import 'package:pharos_ai_runtime/network/http_transport.dart';
import 'package:test/test.dart';

class _FakeHttpTransport extends HttpTransport {
  Uri? capturedUri;
  Map<String, String>? capturedHeaders;
  String? capturedBody;
  String responseBody =
      '{"choices": [{"message": {"content": "Paris."}}]}';

  @override
  Future<String> post({
    required Uri uri,
    required Map<String, String> headers,
    required String body,
  }) async {
    capturedUri = uri;
    capturedHeaders = headers;
    capturedBody = body;

    return responseBody;
  }
}

void main() {
  const request = ModelRequest(
    systemPrompt: 'You are a helpful assistant.',
    userPrompt: 'What is the capital of France?',
  );
  const modelConfig = ModelConfig(model: 'gpt-4', temperature: 0.7);

  test('complete() includes the Authorization header', () async {
    final transport = _FakeHttpTransport();
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );

    await client.complete(request, modelConfig, openAiConfig);

    expect(transport.capturedHeaders!['Authorization'], 'Bearer sk-test');
  });

  test(
    'complete() includes the OpenAI-Organization header when provided',
    () async {
      final transport = _FakeHttpTransport();
      final client = HttpOpenAIClient(transport: transport);
      const openAiConfig = OpenAIConfig(
        apiKey: 'sk-test',
        baseUrl: 'https://api.openai.com/v1/chat/completions',
        organization: 'org-test',
      );

      await client.complete(request, modelConfig, openAiConfig);

      expect(
        transport.capturedHeaders!['OpenAI-Organization'],
        'org-test',
      );
    },
  );

  test(
    'complete() omits the OpenAI-Organization header when not provided',
    () async {
      final transport = _FakeHttpTransport();
      final client = HttpOpenAIClient(transport: transport);
      const openAiConfig = OpenAIConfig(
        apiKey: 'sk-test',
        baseUrl: 'https://api.openai.com/v1/chat/completions',
      );

      await client.complete(request, modelConfig, openAiConfig);

      expect(
        transport.capturedHeaders!.containsKey('OpenAI-Organization'),
        isFalse,
      );
    },
  );

  test('complete() encodes model correctly', () async {
    final transport = _FakeHttpTransport();
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );

    await client.complete(request, modelConfig, openAiConfig);

    final decoded = jsonDecode(transport.capturedBody!) as Map<String, dynamic>;
    expect(decoded['model'], 'gpt-4');
  });

  test('complete() encodes temperature correctly', () async {
    final transport = _FakeHttpTransport();
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );

    await client.complete(request, modelConfig, openAiConfig);

    final decoded = jsonDecode(transport.capturedBody!) as Map<String, dynamic>;
    expect(decoded['temperature'], 0.7);
  });

  test('complete() encodes the system message correctly', () async {
    final transport = _FakeHttpTransport();
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );

    await client.complete(request, modelConfig, openAiConfig);

    final decoded = jsonDecode(transport.capturedBody!) as Map<String, dynamic>;
    final messages = decoded['messages'] as List<dynamic>;
    final systemMessage = messages[0] as Map<String, dynamic>;

    expect(systemMessage['role'], 'system');
    expect(systemMessage['content'], 'You are a helpful assistant.');
  });

  test('complete() encodes the user message correctly', () async {
    final transport = _FakeHttpTransport();
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );

    await client.complete(request, modelConfig, openAiConfig);

    final decoded = jsonDecode(transport.capturedBody!) as Map<String, dynamic>;
    final messages = decoded['messages'] as List<dynamic>;
    final userMessage = messages[1] as Map<String, dynamic>;

    expect(userMessage['role'], 'user');
    expect(userMessage['content'], 'What is the capital of France?');
  });

  test(
    'complete() extracts choices[0].message.content from the response',
    () async {
      final transport = _FakeHttpTransport()
        ..responseBody =
            '{"choices": [{"message": {"content": "Extracted text."}}]}';
      final client = HttpOpenAIClient(transport: transport);
      const openAiConfig = OpenAIConfig(
        apiKey: 'sk-test',
        baseUrl: 'https://api.openai.com/v1/chat/completions',
      );

      final result = await client.complete(request, modelConfig, openAiConfig);

      expect(result.text, 'Extracted text.');
    },
  );

  test('complete() returns the correct OpenAIResult.text', () async {
    final transport = _FakeHttpTransport();
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );

    final result = await client.complete(request, modelConfig, openAiConfig);

    expect(result.text, 'Paris.');
  });
}
