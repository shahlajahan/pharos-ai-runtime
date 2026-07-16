import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/models/model_response.dart';
import 'package:pharos_ai_runtime/models/openai_client.dart';
import 'package:pharos_ai_runtime/models/openai_config.dart';
import 'package:test/test.dart';

class _FakeOpenAIClient extends OpenAIClient {
  ModelRequest? capturedRequest;
  OpenAIConfig? capturedConfig;

  @override
  Future<ModelResponse> complete(
    ModelRequest request,
    OpenAIConfig config,
  ) async {
    capturedRequest = request;
    capturedConfig = config;

    return const ModelResponse(text: 'Fake response');
  }
}

void main() {
  test('complete() returns a ModelResponse', () async {
    final client = _FakeOpenAIClient();
    const request = ModelRequest(
      systemPrompt: 'You are a helpful assistant.',
      userPrompt: 'What is the capital of France?',
    );
    const config = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1',
    );

    final response = await client.complete(request, config);

    expect(response.text, 'Fake response');
  });

  test('complete() passes the request through unchanged', () async {
    final client = _FakeOpenAIClient();
    const request = ModelRequest(
      systemPrompt: 'You are a helpful assistant.',
      userPrompt: 'What is the capital of France?',
    );
    const config = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1',
    );

    await client.complete(request, config);

    expect(client.capturedRequest, same(request));
  });

  test('complete() passes the config through unchanged', () async {
    final client = _FakeOpenAIClient();
    const request = ModelRequest(
      systemPrompt: 'You are a helpful assistant.',
      userPrompt: 'What is the capital of France?',
    );
    const config = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1',
    );

    await client.complete(request, config);

    expect(client.capturedConfig, same(config));
  });
}
