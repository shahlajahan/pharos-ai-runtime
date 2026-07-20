import 'package:pharos_ai_runtime/models/model_provider.dart';

import 'job.dart';

class ExecutionContext {
  ExecutionContext({
    required this.sessionId,
    required this.startedAt,
    required this.environment,
    required this.job,
    required this.modelProvider,
  });

  final String sessionId;
  final DateTime startedAt;
  final String environment;
  final Job job;
  final ModelProvider modelProvider;
}
