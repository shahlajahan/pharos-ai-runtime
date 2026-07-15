import 'package:pharos_ai_runtime/runtime/execution_step.dart';
import 'package:test/test.dart';

void main() {
  test('ExecutionStep stores id and name', () {
    const step = ExecutionStep(id: 'step-1', name: 'agent-execution');

    expect(step.id, 'step-1');
    expect(step.name, 'agent-execution');
  });
}
