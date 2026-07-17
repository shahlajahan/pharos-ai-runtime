import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/tooling/tool.dart';
import 'package:pharos_ai_runtime/tooling/tool_context.dart';
import 'package:pharos_ai_runtime/tooling/tool_definition.dart';
import 'package:pharos_ai_runtime/tooling/tool_registry.dart';
import 'package:test/test.dart';

class _FakeTool extends Tool {
  @override
  String get id => 'fake-tool';

  @override
  Future<Result> execute(ToolContext context) async =>
      Result.success('executed');
}

void main() {
  test('ToolRegistry defaults to empty and resolves nothing', () {
    const registry = ToolRegistry();

    expect(registry.find('fake-tool'), isNull);
  });

  test('ToolRegistry resolves a Tool registered via constructor injection', () {
    final tool = _FakeTool();
    final registry = ToolRegistry(tools: {tool.id: tool});

    expect(registry.find('fake-tool'), same(tool));
    expect(registry.find('missing'), isNull);
  });

  test('ToolRegistry.definitions() returns an empty list when empty', () {
    const registry = ToolRegistry();

    expect(registry.definitions(), isEmpty);
  });

  test('ToolRegistry.definitions() returns the stored ToolDefinitions', () {
    const definition = ToolDefinition(
      id: 'fake-tool',
      description: 'A fake tool.',
    );
    const registry = ToolRegistry(definitions: {'fake-tool': definition});

    expect(registry.definitions(), [definition]);
  });
}
