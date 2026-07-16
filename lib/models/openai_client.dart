import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/models/model_response.dart';
import 'package:pharos_ai_runtime/models/openai_config.dart';

abstract class OpenAIClient {
  Future<ModelResponse> complete(ModelRequest request, OpenAIConfig config);
}
