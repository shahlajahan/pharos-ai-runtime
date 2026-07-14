import 'job.dart';

class ExecutionContext {
  ExecutionContext({
    required this.sessionId,
    required this.startedAt,
    required this.environment,
    required this.job,
  });

  final String sessionId;
  final DateTime startedAt;
  final String environment;
  final Job job;
}