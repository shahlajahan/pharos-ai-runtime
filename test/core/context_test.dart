import 'package:pharos_ai_runtime/core/context.dart';
import 'package:pharos_ai_runtime/core/job.dart';
import 'package:pharos_ai_runtime/models/mock_model_provider.dart';
import 'package:test/test.dart';

void main() {
  test('ExecutionContext exposes its Job', () {
    final job = Job(
      id: 'job-1',
      agentId: 'marketing',
      createdAt: DateTime(2024, 1, 1),
    );
    final context = ExecutionContext(
      sessionId: 'session-1',
      startedAt: DateTime(2024, 1, 1),
      environment: 'test',
      job: job,
      modelProvider: MockModelProvider(),
    );

    expect(context.job, same(job));
  });

  test('ExecutionContext exposes its ModelProvider', () {
    final job = Job(
      id: 'job-1',
      agentId: 'marketing',
      createdAt: DateTime(2024, 1, 1),
    );
    final modelProvider = MockModelProvider();
    final context = ExecutionContext(
      sessionId: 'session-1',
      startedAt: DateTime(2024, 1, 1),
      environment: 'test',
      job: job,
      modelProvider: modelProvider,
    );

    expect(context.modelProvider, same(modelProvider));
  });
}
