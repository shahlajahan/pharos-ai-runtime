import 'package:pharos_ai_runtime/company/intent/intent_status.dart';
import 'package:test/test.dart';

void main() {
  test('IntentStatus values are correct', () {
    expect(IntentStatus.values, [
      IntentStatus.proposed,
      IntentStatus.approved,
      IntentStatus.active,
      IntentStatus.completed,
      IntentStatus.cancelled,
    ]);
  });
}
