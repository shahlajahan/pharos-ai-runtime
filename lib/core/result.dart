class Result {
  const Result._({required this.success, required this.message});

  factory Result.success(String message) =>
      Result._(success: true, message: message);

  factory Result.failure(String message) =>
      Result._(success: false, message: message);

  final bool success;
  final String message;
}
