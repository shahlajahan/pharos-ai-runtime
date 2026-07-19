import 'package:pharos_ai_runtime/company/work/work_outcome.dart';
import 'package:test/test.dart';

void main() {
  test('WorkOutcome can be instantiated as a placeholder aggregate', () {
    const outcome = WorkOutcome();

    expect(outcome, isNotNull);
  });
}
