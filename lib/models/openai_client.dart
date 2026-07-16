import 'package:pharos_ai_runtime/models/model_config.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/models/openai_config.dart';
import 'package:pharos_ai_runtime/models/openai_result.dart';

abstract class OpenAIClient {
  Future<OpenAIResult> complete(
    ModelRequest request,
    ModelConfig modelConfig,
    OpenAIConfig openAiConfig,
  );
}
