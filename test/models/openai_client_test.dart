import 'package:pharos_ai_runtime/models/model_config.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/models/openai_client.dart';
import 'package:pharos_ai_runtime/models/openai_config.dart';
import 'package:pharos_ai_runtime/models/openai_result.dart';
import 'package:test/test.dart';

class _FakeOpenAIClient extends OpenAIClient {
  ModelRequest? capturedRequest;
  ModelConfig? capturedModelConfig;
  OpenAIConfig? capturedOpenAiConfig;

  @override
  Future<OpenAIResult> complete(
    ModelRequest request,
    ModelConfig modelConfig,
    OpenAIConfig openAiConfig,
  ) async {
    capturedRequest = request;
    capturedModelConfig = modelConfig;
    capturedOpenAiConfig = openAiConfig;

    return const OpenAIResult(text: 'Fake response');
  }
}

void main() {
  test('complete() returns an OpenAIResult', () async {
    final client = _FakeOpenAIClient();
    const request = ModelRequest(
      systemPrompt: 'You are a helpful assistant.',
      userPrompt: 'What is the capital of France?',
    );
    const modelConfig = ModelConfig(model: 'gpt-4', temperature: 0.7);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1',
    );

    final result = await client.complete(request, modelConfig, openAiConfig);

    expect(result.text, 'Fake response');
  });

  test('complete() passes the request through unchanged', () async {
    final client = _FakeOpenAIClient();
    const request = ModelRequest(
      systemPrompt: 'You are a helpful assistant.',
      userPrompt: 'What is the capital of France?',
    );
    const modelConfig = ModelConfig(model: 'gpt-4', temperature: 0.7);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1',
    );

    await client.complete(request, modelConfig, openAiConfig);

    expect(client.capturedRequest, same(request));
  });

  test('complete() passes the modelConfig through unchanged', () async {
    final client = _FakeOpenAIClient();
    const request = ModelRequest(
      systemPrompt: 'You are a helpful assistant.',
      userPrompt: 'What is the capital of France?',
    );
    const modelConfig = ModelConfig(model: 'gpt-4', temperature: 0.7);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1',
    );

    await client.complete(request, modelConfig, openAiConfig);

    expect(client.capturedModelConfig, same(modelConfig));
  });

  test('complete() passes the openAiConfig through unchanged', () async {
    final client = _FakeOpenAIClient();
    const request = ModelRequest(
      systemPrompt: 'You are a helpful assistant.',
      userPrompt: 'What is the capital of France?',
    );
    const modelConfig = ModelConfig(model: 'gpt-4', temperature: 0.7);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1',
    );

    await client.complete(request, modelConfig, openAiConfig);

    expect(client.capturedOpenAiConfig, same(openAiConfig));
  });
}
