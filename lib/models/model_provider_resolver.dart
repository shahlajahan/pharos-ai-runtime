import 'package:pharos_ai_runtime/models/mock_model_provider.dart';
import 'package:pharos_ai_runtime/models/model_provider.dart';
import 'package:pharos_ai_runtime/models/openai_environment.dart';
import 'package:pharos_ai_runtime/models/openai_provider_factory.dart';

abstract final class ModelProviderResolver {
  static ModelProvider resolve({
    required bool useOpenAI,
    required OpenAIEnvironment environment,
  }) {
    if (!useOpenAI) {
      return MockModelProvider();
    }

    return OpenAIProviderFactory().build(environment);
  }
}
