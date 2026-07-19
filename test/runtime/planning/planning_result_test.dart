import 'package:pharos_ai_runtime/runtime/planning/planning_result.dart';
import 'package:test/test.dart';

void main() {
  test('PlanningResult is instantiable', () {
    const result = PlanningResult();

    expect(result, isNotNull);
  });
}
