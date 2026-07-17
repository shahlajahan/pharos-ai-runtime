import 'package:pharos_ai_runtime/models/model_exception.dart';
import 'package:pharos_ai_runtime/models/model_provider.dart';
import 'package:pharos_ai_runtime/models/model_registry.dart';

abstract final class ModelProviderResolver {
  static ModelProvider resolve({
    required String provider,
    required ModelRegistry registry,
  }) {
    if (!registry.contains(provider)) {
      throw ModelException('Unknown model provider: $provider');
    }

    return registry.provider(provider);
  }
}
