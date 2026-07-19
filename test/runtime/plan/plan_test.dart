import 'package:pharos_ai_runtime/runtime/plan/plan.dart';
import 'package:test/test.dart';

class _FakePlan implements Plan {
  @override
  String get id => 'p1';

  @override
  String get title => 'Ship the release';
}

void main() {
  test('Fake Plan implementation works, exposing id and title', () {
    final plan = _FakePlan();

    expect(plan, isA<Plan>());
    expect(plan.id, 'p1');
    expect(plan.title, 'Ship the release');
  });
}
