import 'package:pharos_ai_runtime/models/model_exception.dart';
import 'package:pharos_ai_runtime/models/model_provider.dart';
import 'package:pharos_ai_runtime/models/model_provider_resolver.dart';
import 'package:pharos_ai_runtime/models/model_registry.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/models/model_response.dart';
import 'package:test/test.dart';

class _FakeModelProvider extends ModelProvider {
  @override
  Future<ModelResponse> generate(ModelRequest request) async {
    return const ModelResponse(text: 'fake response');
  }
}

void main() {
  test('resolve() returns the provider registered under the given name', () {
    final fakeProvider = _FakeModelProvider();
    final registry = ModelRegistry(providers: {'fake': fakeProvider});

    final resolved = ModelProviderResolver.resolve(
      provider: 'fake',
      registry: registry,
    );

    expect(resolved, same(fakeProvider));
  });

  test('resolve() throws ModelException for an unknown provider', () {
    const registry = ModelRegistry();

    expect(
      () => ModelProviderResolver.resolve(
        provider: 'unknown',
        registry: registry,
      ),
      throwsA(
        isA<ModelException>().having(
          (e) => e.message,
          'message',
          'Unknown model provider: unknown',
        ),
      ),
    );
  });

  test('resolve() works with any registered ModelProvider without '
      'OpenAI-specific logic', () {
    final registry = ModelRegistry(
      providers: {
        'first': _FakeModelProvider(),
        'second': _FakeModelProvider(),
      },
    );

    final first = ModelProviderResolver.resolve(
      provider: 'first',
      registry: registry,
    );
    final second = ModelProviderResolver.resolve(
      provider: 'second',
      registry: registry,
    );

    expect(first, isA<ModelProvider>());
    expect(second, isA<ModelProvider>());
  });
}
