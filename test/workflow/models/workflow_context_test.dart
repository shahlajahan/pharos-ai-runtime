import 'package:pharos_ai_runtime/workflow/models/workflow_context.dart';
import 'package:test/test.dart';

void main() {
  test('WorkflowContext stores company, market, and finance data', () {
    const context = WorkflowContext(
      company: {'name': 'Pharos'},
      market: {'trend': 'growth'},
      finance: {'budget': 5000},
    );

    expect(context.company, {'name': 'Pharos'});
    expect(context.market, {'trend': 'growth'});
    expect(context.finance, {'budget': 5000});
  });

  test('WorkflowContext is constructible as a compile-time constant', () {
    const context = WorkflowContext(company: {}, market: {}, finance: {});

    expect(context, isA<WorkflowContext>());
  });
}
