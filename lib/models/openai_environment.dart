class OpenAIEnvironment {
  const OpenAIEnvironment({
    required this.apiKey,
    required this.baseUrl,
    required this.model,
    required this.temperature,
    this.organization,
  });

  final String apiKey;
  final String baseUrl;
  final String model;
  final double temperature;
  final String? organization;

  factory OpenAIEnvironment.fromMap(Map<String, String> environment) {
    final apiKey = environment['OPENAI_API_KEY'];

    if (apiKey == null) {
      throw StateError('Missing required environment variable: OPENAI_API_KEY');
    }

    final baseUrl = environment['OPENAI_BASE_URL'];

    if (baseUrl == null) {
      throw StateError(
        'Missing required environment variable: OPENAI_BASE_URL',
      );
    }

    final model = environment['OPENAI_MODEL'];

    if (model == null) {
      throw StateError('Missing required environment variable: OPENAI_MODEL');
    }

    final temperatureValue = environment['OPENAI_TEMPERATURE'];

    if (temperatureValue == null) {
      throw StateError(
        'Missing required environment variable: OPENAI_TEMPERATURE',
      );
    }

    final temperature = double.parse(temperatureValue);

    return OpenAIEnvironment(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      temperature: temperature,
      organization: environment['OPENAI_ORGANIZATION'],
    );
  }
}
