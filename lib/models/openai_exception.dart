class OpenAIException implements Exception {
  const OpenAIException(this.message);

  final String message;

  @override
  String toString() => message;
}
