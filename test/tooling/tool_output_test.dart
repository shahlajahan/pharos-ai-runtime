import 'package:pharos_ai_runtime/tooling/tool_output.dart';
import 'package:test/test.dart';

void main() {
  test('ToolOutput stores toolCallId, toolName, success, and content', () {
    const output = ToolOutput(
      toolCallId: 'call_1',
      toolName: 'search',
      success: true,
      content: 'result text',
    );

    expect(output.toolCallId, 'call_1');
    expect(output.toolName, 'search');
    expect(output.success, isTrue);
    expect(output.content, 'result text');
  });

  test('ToolOutput can represent a successful execution', () {
    const output = ToolOutput(
      toolCallId: 'call_1',
      toolName: 'search',
      success: true,
      content: 'ok',
    );

    expect(output.success, isTrue);
  });

  test('ToolOutput can represent a failed execution', () {
    const output = ToolOutput(
      toolCallId: 'call_1',
      toolName: 'search',
      success: false,
      content: 'Tool "search" not found.',
    );

    expect(output.success, isFalse);
  });
}
