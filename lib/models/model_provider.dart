import 'package:pharos_ai_runtime/models/model_config.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/models/model_response.dart';
import 'package:pharos_ai_runtime/models/streaming_response.dart';

abstract class ModelProvider {
  Future<ModelResponse> generate(ModelRequest request);

  Future<StreamingResponse> stream(
    ModelRequest request,
    ModelConfig modelConfig,
  ) {
    throw UnimplementedError();
  }
}
