import 'package:pharos_ai_runtime/models/openai_environment.dart';
import 'package:test/test.dart';

Map<String, String> _validEnvironment({String? organization}) {
  final environment = {
    'OPENAI_API_KEY': 'sk-test-key',
    'OPENAI_BASE_URL': 'https://api.openai.com/v1',
    'OPENAI_MODEL': 'gpt-4',
    'OPENAI_TEMPERATURE': '0.7',
  };

  if (organization != null) {
    environment['OPENAI_ORGANIZATION'] = organization;
  }

  return environment;
}

void main() {
  test('fromMap() stores all required values', () {
    final environment = OpenAIEnvironment.fromMap(_validEnvironment());

    expect(environment.apiKey, 'sk-test-key');
    expect(environment.baseUrl, 'https://api.openai.com/v1');
    expect(environment.model, 'gpt-4');
    expect(environment.temperature, 0.7);
  });

  test('fromMap() stores organization when present', () {
    final environment = OpenAIEnvironment.fromMap(
      _validEnvironment(organization: 'org-123'),
    );

    expect(environment.organization, 'org-123');
  });

  test('fromMap() leaves organization null when absent', () {
    final environment = OpenAIEnvironment.fromMap(_validEnvironment());

    expect(environment.organization, isNull);
  });

  test('fromMap() throws StateError when OPENAI_API_KEY is missing', () {
    final map = _validEnvironment()..remove('OPENAI_API_KEY');

    expect(() => OpenAIEnvironment.fromMap(map), throwsStateError);
  });

  test('fromMap() throws StateError when OPENAI_BASE_URL is missing', () {
    final map = _validEnvironment()..remove('OPENAI_BASE_URL');

    expect(() => OpenAIEnvironment.fromMap(map), throwsStateError);
  });

  test('fromMap() throws StateError when OPENAI_MODEL is missing', () {
    final map = _validEnvironment()..remove('OPENAI_MODEL');

    expect(() => OpenAIEnvironment.fromMap(map), throwsStateError);
  });

  test('fromMap() throws StateError when OPENAI_TEMPERATURE is missing', () {
    final map = _validEnvironment()..remove('OPENAI_TEMPERATURE');

    expect(() => OpenAIEnvironment.fromMap(map), throwsStateError);
  });

  test(
    'fromMap() throws FormatException when OPENAI_TEMPERATURE is invalid',
    () {
      final map = _validEnvironment();
      map['OPENAI_TEMPERATURE'] = 'not-a-number';

      expect(() => OpenAIEnvironment.fromMap(map), throwsFormatException);
    },
  );

  test('fromMap() preserves values exactly without trimming', () {
    final map = {
      'OPENAI_API_KEY': '  sk-test-key  ',
      'OPENAI_BASE_URL': ' https://api.openai.com/v1 ',
      'OPENAI_MODEL': ' gpt-4 ',
      'OPENAI_TEMPERATURE': '0.7',
      'OPENAI_ORGANIZATION': ' org-123 ',
    };

    final environment = OpenAIEnvironment.fromMap(map);

    expect(environment.apiKey, '  sk-test-key  ');
    expect(environment.baseUrl, ' https://api.openai.com/v1 ');
    expect(environment.model, ' gpt-4 ');
    expect(environment.organization, ' org-123 ');
  });
}
