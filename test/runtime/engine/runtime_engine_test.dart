import 'package:pharos_ai_runtime/runtime/engine/runtime_engine.dart';
import 'package:pharos_ai_runtime/runtime/intent/runtime_intent.dart';
import 'package:pharos_ai_runtime/workflow/workflow_result.dart';
import 'package:test/test.dart';

class _FakeRuntimeIntent implements RuntimeIntent {
  @override
  String get id => 'i1';

  @override
  String get title => 'Release version 2.0';
}

class _FakeRuntimeEngine implements RuntimeEngine {
  @override
  Future<WorkflowResult> execute(RuntimeIntent intent) async {
    return const WorkflowResult(stepResults: []);
  }
}

void main() {
  test('RuntimeEngine can be implemented', () {
    final engine = _FakeRuntimeEngine();

    expect(engine, isA<RuntimeEngine>());
  });

  test('A fake implementation returns a WorkflowResult', () async {
    final engine = _FakeRuntimeEngine();

    final result = await engine.execute(_FakeRuntimeIntent());

    expect(result, isA<WorkflowResult>());
  });
}
