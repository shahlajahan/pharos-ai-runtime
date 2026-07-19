import 'package:pharos_ai_runtime/runtime/intent/runtime_intent_result.dart';
import 'package:test/test.dart';

void main() {
  test('RuntimeIntentResult is instantiable', () {
    const result = RuntimeIntentResult();

    expect(result, isNotNull);
  });
}
