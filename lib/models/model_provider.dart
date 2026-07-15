import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/models/model_response.dart';

abstract class ModelProvider {
  Future<ModelResponse> generate(ModelRequest request);
}
