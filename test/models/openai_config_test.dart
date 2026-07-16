import 'package:pharos_ai_runtime/models/openai_config.dart';
import 'package:test/test.dart';

void main() {
  test('OpenAIConfig stores apiKey', () {
    const config = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1',
      organization: 'org-test',
    );

    expect(config.apiKey, 'sk-test');
  });

  test('OpenAIConfig stores baseUrl', () {
    const config = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1',
      organization: 'org-test',
    );

    expect(config.baseUrl, 'https://api.openai.com/v1');
  });

  test('OpenAIConfig stores organization', () {
    const config = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1',
      organization: 'org-test',
    );

    expect(config.organization, 'org-test');
  });

  test('OpenAIConfig.organization may be null', () {
    const config = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1',
    );

    expect(config.organization, isNull);
  });

  test('OpenAIConfig is immutable', () {
    const a = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1',
      organization: 'org-test',
    );
    const b = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1',
      organization: 'org-test',
    );

    // Two const instances with equal field values are canonicalized to the
    // same object by Dart, which is only possible because the constructor
    // is const and every field is final.
    expect(identical(a, b), isTrue);
  });
}
