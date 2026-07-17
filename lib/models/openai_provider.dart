import 'package:pharos_ai_runtime/models/model_config.dart';
import 'package:pharos_ai_runtime/models/model_provider.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/models/model_response.dart';
import 'package:pharos_ai_runtime/models/openai_client.dart';
import 'package:pharos_ai_runtime/models/openai_config.dart';

class OpenAIProvider extends ModelProvider {
  OpenAIProvider({
    required OpenAIClient client,
    required ModelConfig modelConfig,
    required OpenAIConfig openAiConfig,
  }) : _client = client,
       _modelConfig = modelConfig,
       _openAiConfig = openAiConfig;

  final OpenAIClient _client;
  final ModelConfig _modelConfig;
  final OpenAIConfig _openAiConfig;

  @override
  Future<ModelResponse> generate(ModelRequest request) async {
    final result = await _client.complete(request, _modelConfig, _openAiConfig);

    return ModelResponse(text: result.text, toolCalls: result.toolCalls);
  }
}
