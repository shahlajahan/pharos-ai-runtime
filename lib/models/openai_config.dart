class OpenAIConfig {
  const OpenAIConfig({
    required this.apiKey,
    required this.baseUrl,
    this.organization,
  });

  final String apiKey;
  final String baseUrl;
  final String? organization;
}
