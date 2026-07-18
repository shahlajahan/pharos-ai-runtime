import 'package:pharos_ai_runtime/tooling/tool_context.dart';
import 'package:test/test.dart';

void main() {
  test('ToolContext stores toolId', () {
    const context = ToolContext(toolId: 'tool-1');

    expect(context.toolId, 'tool-1');
  });

  test('ToolContext defaults arguments to an empty JSON object', () {
    const context = ToolContext(toolId: 'tool-1');

    expect(context.arguments, '{}');
  });

  test('ToolContext stores the given arguments', () {
    const context = ToolContext(
      toolId: 'tool-1',
      arguments: '{"query":"Paris"}',
    );

    expect(context.arguments, '{"query":"Paris"}');
  });
}
