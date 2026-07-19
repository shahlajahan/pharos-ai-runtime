import 'package:pharos_ai_runtime/runtime/intent/runtime_intent.dart';
import 'package:pharos_ai_runtime/runtime/planning/planner.dart';
import 'package:pharos_ai_runtime/runtime/planning/planning_request.dart';
import 'package:pharos_ai_runtime/runtime/planning/planning_result.dart';
import 'package:test/test.dart';

class _FakeRuntimeIntent implements RuntimeIntent {
  @override
  String get id => 'i1';

  @override
  String get title => 'Release version 2.0';
}

class _FakePlanner implements Planner {
  @override
  Future<PlanningResult> plan(PlanningRequest request) async {
    return const PlanningResult();
  }
}

void main() {
  test('Planner can be implemented with a fake implementation', () async {
    final planner = _FakePlanner();
    final request = PlanningRequest(intent: _FakeRuntimeIntent());

    final result = await planner.plan(request);

    expect(result, isA<PlanningResult>());
  });
}
