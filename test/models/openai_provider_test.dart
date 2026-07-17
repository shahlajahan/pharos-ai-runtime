import 'package:pharos_ai_runtime/models/model_config.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/models/openai_client.dart';
import 'package:pharos_ai_runtime/models/openai_config.dart';
import 'package:pharos_ai_runtime/models/openai_provider.dart';
import 'package:pharos_ai_runtime/models/openai_result.dart';
import 'package:pharos_ai_runtime/tooling/tool_definition.dart';
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

    return const OpenAIResult(text: 'Paris is the capital of France.');
  }
}

void main() {
  const request = ModelRequest(
    systemPrompt: 'You are a helpful assistant.',
    userPrompt: 'What is the capital of France?',
  );
  const modelConfig = ModelConfig(model: 'gpt-4', temperature: 0.7);
  const openAiConfig = OpenAIConfig(
    apiKey: 'sk-test',
    baseUrl: 'https://api.openai.com/v1/chat/completions',
  );

  test('generate() forwards the request unchanged', () async {
    final client = _FakeOpenAIClient();
    final provider = OpenAIProvider(
      client: client,
      modelConfig: modelConfig,
      openAiConfig: openAiConfig,
    );

    await provider.generate(request);

    expect(client.capturedRequest, same(request));
  });

  test('generate() forwards the modelConfig unchanged', () async {
    final client = _FakeOpenAIClient();
    final provider = OpenAIProvider(
      client: client,
      modelConfig: modelConfig,
      openAiConfig: openAiConfig,
    );

    await provider.generate(request);

    expect(client.capturedModelConfig, same(modelConfig));
  });

  test('generate() forwards the openAiConfig unchanged', () async {
    final client = _FakeOpenAIClient();
    final provider = OpenAIProvider(
      client: client,
      modelConfig: modelConfig,
      openAiConfig: openAiConfig,
    );

    await provider.generate(request);

    expect(client.capturedOpenAiConfig, same(openAiConfig));
  });

  test('generate() turns OpenAIResult.text into ModelResponse.text', () async {
    final client = _FakeOpenAIClient();
    final provider = OpenAIProvider(
      client: client,
      modelConfig: modelConfig,
      openAiConfig: openAiConfig,
    );

    final response = await provider.generate(request);

    expect(response.text, 'Paris is the capital of France.');
  });

  test('generate() forwards request.tools unchanged', () async {
    final client = _FakeOpenAIClient();
    final provider = OpenAIProvider(
      client: client,
      modelConfig: modelConfig,
      openAiConfig: openAiConfig,
    );
    const requestWithTools = ModelRequest(
      systemPrompt: 'You are a helpful assistant.',
      userPrompt: 'What is the capital of France?',
      tools: [ToolDefinition(id: 'search', description: 'Search the web.')],
    );

    await provider.generate(requestWithTools);

    expect(client.capturedRequest, same(requestWithTools));
    expect(client.capturedRequest!.tools, requestWithTools.tools);
  });
}
