import 'package:pharos_ai_runtime/core/job.dart';
import 'package:test/test.dart';

void main() {
  test('Job stores id, agentId, and createdAt', () {
    final createdAt = DateTime(2024, 1, 1);
    final job = Job(id: 'job-1', agentId: 'marketing', createdAt: createdAt);

    expect(job.id, 'job-1');
    expect(job.agentId, 'marketing');
    expect(job.createdAt, createdAt);
  });
}
