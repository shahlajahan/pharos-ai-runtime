import 'package:pharos_ai_runtime/runtime/intent/runtime_intent.dart';
import 'package:pharos_ai_runtime/runtime/planning/planning_request.dart';
import 'package:test/test.dart';

class _FakeRuntimeIntent implements RuntimeIntent {
  @override
  String get id => 'i1';

  @override
  String get title => 'Release version 2.0';
}

void main() {
  test('PlanningRequest stores RuntimeIntent', () {
    final intent = _FakeRuntimeIntent();
    final request = PlanningRequest(intent: intent);

    expect(request.intent, same(intent));
  });
}
