import 'package:pharos_ai_runtime/tooling/tool_context.dart';
import 'package:test/test.dart';

void main() {
  test('ToolContext stores only toolId', () {
    const context = ToolContext(toolId: 'tool-1');

    expect(context.toolId, 'tool-1');
  });
}
