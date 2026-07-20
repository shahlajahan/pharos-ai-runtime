import 'dart:convert';

import 'package:pharos_ai_runtime/models/conversation.dart';
import 'package:pharos_ai_runtime/models/http_openai_client.dart';
import 'package:pharos_ai_runtime/models/model_config.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/models/openai_config.dart';
import 'package:pharos_ai_runtime/models/openai_provider.dart';
import 'package:pharos_ai_runtime/network/http_transport.dart';
import 'package:pharos_ai_runtime/network/http_transport_response.dart';
import 'package:test/test.dart';

class _FakeHttpTransport extends HttpTransport {
  Map<String, String>? capturedHeaders;
  String? capturedBody;

  @override
  Future<HttpTransportResponse> post({
    required Uri uri,
    required Map<String, String> headers,
    required String body,
  }) async {
    capturedHeaders = headers;
    capturedBody = body;

    return HttpTransportResponse(
      statusCode: 200,
      headers: const {},
      body: jsonEncode({
        'choices': [
          {
            'message': {
              'role': 'assistant',
              'content': 'Paris is the capital of France.',
            },
          },
        ],
      }),
    );
  }
}

void main() {
  test('ModelRequest -> OpenAIProvider -> HttpOpenAIClient -> HttpTransport '
      '-> OpenAIResult -> ModelResponse works end-to-end', () async {
    final transport = _FakeHttpTransport();
    final client = HttpOpenAIClient(transport: transport);
    const modelConfig = ModelConfig(model: 'gpt-4', temperature: 0.7);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1',
    );
    final provider = OpenAIProvider(
      client: client,
      modelConfig: modelConfig,
      openAiConfig: openAiConfig,
    );
    const request = ModelRequest(
      conversation: Conversation(
        messages: [
          SystemMessage(content: 'You are a helpful assistant.'),
          UserMessage(content: 'What is the capital of France?'),
        ],
      ),
    );

    final response = await provider.generate(request);

    expect(response.text, 'Paris is the capital of France.');

    expect(transport.capturedHeaders!['Authorization'], 'Bearer sk-test');

    final decodedBody =
        jsonDecode(transport.capturedBody!) as Map<String, dynamic>;

    expect(decodedBody['model'], 'gpt-4');
    expect(decodedBody['temperature'], 0.7);

    final messages = decodedBody['messages'] as List<dynamic>;
    final systemMessage = messages[0] as Map<String, dynamic>;
    final userMessage = messages[1] as Map<String, dynamic>;

    expect(systemMessage['role'], 'system');
    expect(systemMessage['content'], 'You are a helpful assistant.');
    expect(userMessage['role'], 'user');
    expect(userMessage['content'], 'What is the capital of France?');
  });
}
