import 'package:pharos_ai_runtime/models/openai_environment.dart';
import 'package:pharos_ai_runtime/models/openai_provider.dart';
import 'package:pharos_ai_runtime/models/openai_provider_factory.dart';
import 'package:test/test.dart';

void main() {
  test('build() returns an OpenAIProvider', () {
    const factory = OpenAIProviderFactory();
    const environment = OpenAIEnvironment(
      apiKey: 'sk-test-key',
      baseUrl: 'https://api.openai.com/v1',
      model: 'gpt-4',
      temperature: 0.7,
      organization: 'org-123',
    );

    final provider = factory.build(environment);

    expect(provider, isA<OpenAIProvider>());
  });

  test('build() accepts a populated OpenAIEnvironment without throwing', () {
    const factory = OpenAIProviderFactory();
    const environment = OpenAIEnvironment(
      apiKey: 'sk-test-key',
      baseUrl: 'https://api.openai.com/v1',
      model: 'gpt-4',
      temperature: 0.7,
      organization: 'org-123',
    );

    expect(() => factory.build(environment), returnsNormally);
  });

  test('build() succeeds when organization is absent', () {
    const factory = OpenAIProviderFactory();
    const environment = OpenAIEnvironment(
      apiKey: 'sk-test-key',
      baseUrl: 'https://api.openai.com/v1',
      model: 'gpt-4',
      temperature: 0.7,
    );

    final provider = factory.build(environment);

    expect(provider, isA<OpenAIProvider>());
  });

  test('build() does not throw for a valid environment', () {
    const factory = OpenAIProviderFactory();
    const environment = OpenAIEnvironment(
      apiKey: 'sk-test-key',
      baseUrl: 'https://api.openai.com/v1',
      model: 'gpt-4',
      temperature: 0.7,
    );

    expect(() => factory.build(environment), returnsNormally);
  });
}
