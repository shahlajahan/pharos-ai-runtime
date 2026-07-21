import 'package:pharos_ai_runtime/tools/models/tool.dart';
import 'package:pharos_ai_runtime/tools/models/tool_capability.dart';
import 'package:pharos_ai_runtime/tools/models/tool_id.dart';
import 'package:pharos_ai_runtime/tools/models/tool_status.dart';
import 'package:pharos_ai_runtime/tools/registry/tool_registry.dart';
import 'package:test/test.dart';

Tool _tool(String id, {ToolStatus status = ToolStatus.available}) => Tool(
  id: ToolId(id),
  name: id,
  description: '',
  status: status,
  capabilities: {const ToolCapability('search')},
  supportedOperations: const ['search'],
  metadata: const {},
);

void main() {
  test('register() adds a Tool, visible via list()', () {
    final registry = ToolRegistry();

    registry.register(_tool('web-search'));

    expect(registry.list().map((t) => t.id.value), ['web-search']);
  });

  test('register() throws ArgumentError for a duplicate id rather than '
      'silently overwriting it', () {
    final registry = ToolRegistry()..register(_tool('web-search'));

    expect(() => registry.register(_tool('web-search')), throwsArgumentError);
    expect(registry.list(), hasLength(1));
  });

  test('remove() removes a tool by id', () {
    final registry = ToolRegistry()..register(_tool('web-search'));

    registry.remove(const ToolId('web-search'));

    expect(registry.list(), isEmpty);
  });

  test('remove() is a no-op for an id that was never registered', () {
    final registry = ToolRegistry();

    registry.remove(const ToolId('nonexistent'));

    expect(registry.list(), isEmpty);
  });

  test('find() returns the registered tool by id, or null', () {
    final registry = ToolRegistry()..register(_tool('web-search'));

    expect(registry.find(const ToolId('web-search'))?.id.value, 'web-search');
    expect(registry.find(const ToolId('nonexistent')), isNull);
  });

  test('list() returns every registered tool', () {
    final registry = ToolRegistry()
      ..register(_tool('web-search'))
      ..register(_tool('image-generation'));

    expect(registry.list(), hasLength(2));
  });
}
