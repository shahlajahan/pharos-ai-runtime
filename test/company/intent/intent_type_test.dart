import 'package:pharos_ai_runtime/company/intent/intent_type.dart';
import 'package:test/test.dart';

void main() {
  test('IntentType values are correct', () {
    expect(IntentType.values, [
      IntentType.strategic,
      IntentType.operational,
      IntentType.tactical,
    ]);
  });
}
