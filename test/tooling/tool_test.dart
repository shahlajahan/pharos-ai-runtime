import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/tooling/tool.dart';
import 'package:pharos_ai_runtime/tooling/tool_context.dart';
import 'package:test/test.dart';

class _FakeTool extends Tool {
  @override
  String get id => 'fake-tool';

  @override
  Future<Result> execute(ToolContext context) async =>
      Result.success('executed');
}

void main() {
  test('Tool exposes id and execute(context) returning a Result', () async {
    final tool = _FakeTool();

    final result = await tool.execute(const ToolContext(toolId: 'fake-tool'));

    expect(tool.id, 'fake-tool');
    expect(result.success, isTrue);
    expect(result.message, 'executed');
  });
}
