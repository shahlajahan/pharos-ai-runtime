import 'package:pharos_ai_runtime/models/mock_model_provider.dart';
import 'package:pharos_ai_runtime/models/model_provider_resolver.dart';
import 'package:pharos_ai_runtime/models/openai_environment.dart';
import 'package:pharos_ai_runtime/models/openai_provider.dart';
import 'package:test/test.dart';

const _environment = OpenAIEnvironment(
  apiKey: 'sk-test-key',
  baseUrl: 'https://api.openai.com/v1/chat/completions',
  model: 'gpt-4',
  temperature: 0.7,
);

const _environmentWithOrganization = OpenAIEnvironment(
  apiKey: 'sk-test-key',
  baseUrl: 'https://api.openai.com/v1/chat/completions',
  model: 'gpt-4',
  temperature: 0.7,
  organization: 'org-123',
);

void main() {
  test('resolve() returns a MockModelProvider when useOpenAI is false', () {
    final provider = ModelProviderResolver.resolve(
      useOpenAI: false,
      environment: _environment,
    );

    expect(provider, isA<MockModelProvider>());
  });

  test('resolve() returns an OpenAIProvider when useOpenAI is true', () {
    final provider = ModelProviderResolver.resolve(
      useOpenAI: true,
      environment: _environment,
    );

    expect(provider, isA<OpenAIProvider>());
  });

  test('resolve() forwards the given OpenAIEnvironment without throwing, '
      'regardless of whether organization is present', () {
    expect(
      () => ModelProviderResolver.resolve(
        useOpenAI: true,
        environment: _environment,
      ),
      returnsNormally,
    );
    expect(
      () => ModelProviderResolver.resolve(
        useOpenAI: true,
        environment: _environmentWithOrganization,
      ),
      returnsNormally,
    );
  });

  test('resolve() performs no HTTP request while building the provider', () {
    expect(
      () => ModelProviderResolver.resolve(
        useOpenAI: true,
        environment: _environment,
      ),
      returnsNormally,
    );
  });
}
