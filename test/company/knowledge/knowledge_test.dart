import 'package:pharos_ai_runtime/company/knowledge/knowledge.dart';
import 'package:test/test.dart';

void main() {
  test('Knowledge can be instantiated as an empty placeholder aggregate', () {
    const knowledge = Knowledge();

    expect(knowledge, isNotNull);
  });
}
