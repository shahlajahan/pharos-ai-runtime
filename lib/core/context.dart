class ExecutionContext {
  ExecutionContext({
    required this.sessionId,
    required this.startedAt,
    required this.environment,
  });

  final String sessionId;
  final DateTime startedAt;
  final String environment;
}