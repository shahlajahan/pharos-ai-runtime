class ModelException implements Exception {
  const ModelException(this.message);

  final String message;

  @override
  String toString() => message;
}
