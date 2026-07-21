import 'package:pharos_ai_runtime/workflow/models/workflow_result.dart';
import 'package:test/test.dart';

void main() {
  test('WorkflowResult stores every field exactly as constructed', () {
    const result = WorkflowResult(
      success: true,
      completedSteps: ['analyze-market', 'publish'],
      failedSteps: [],
      duration: Duration(minutes: 12),
      outputs: {'reach': 10000},
    );

    expect(result.success, isTrue);
    expect(result.completedSteps, ['analyze-market', 'publish']);
    expect(result.failedSteps, isEmpty);
    expect(result.duration, const Duration(minutes: 12));
    expect(result.outputs, {'reach': 10000});
  });

  test('WorkflowResult is constructible as a compile-time constant', () {
    const result = WorkflowResult(
      success: false,
      completedSteps: [],
      failedSteps: ['publish'],
      duration: Duration.zero,
      outputs: {},
    );

    expect(result.success, isFalse);
  });
}
