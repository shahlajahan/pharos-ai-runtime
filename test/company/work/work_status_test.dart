import 'package:pharos_ai_runtime/company/work/work_status.dart';
import 'package:test/test.dart';

void main() {
  test('WorkStatus has one value per lifecycle state', () {
    expect(WorkStatus.values, [
      WorkStatus.pending,
      WorkStatus.inProgress,
      WorkStatus.completed,
      WorkStatus.cancelled,
    ]);
  });
}
