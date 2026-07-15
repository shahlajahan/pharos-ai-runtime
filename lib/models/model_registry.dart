import 'package:pharos_ai_runtime/models/model_provider.dart';

class ModelRegistry {
  const ModelRegistry({Map<String, ModelProvider> providers = const {}})
    : _providers = providers;

  final Map<String, ModelProvider> _providers;

  ModelProvider provider(String name) {
    final provider = _providers[name];

    if (provider == null) {
      throw ArgumentError.value(
        name,
        'name',
        'No ModelProvider registered for this name.',
      );
    }

    return provider;
  }

  bool contains(String name) => _providers.containsKey(name);
}
