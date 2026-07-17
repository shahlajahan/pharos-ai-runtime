import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/tooling/tool.dart';
import 'package:pharos_ai_runtime/tooling/tool_call.dart';
import 'package:pharos_ai_runtime/tooling/tool_context.dart';
import 'package:pharos_ai_runtime/tooling/tool_invoker.dart';
import 'package:pharos_ai_runtime/tooling/tool_registry.dart';
import 'package:test/test.dart';

class _FakeTool extends Tool {
  @override
  String get id => 'fake-tool';

  @override
  Future<Result> execute(ToolContext context) async =>
      Result.success('executed');
}

class _ThrowingTool extends Tool {
  @override
  String get id => 'throwing-tool';

  @override
  Future<Result> execute(ToolContext context) async {
    throw StateError('tool boom');
  }
}

class _CapturingTool extends Tool {
  ToolContext? capturedContext;

  @override
  String get id => 'capturing-tool';

  @override
  Future<Result> execute(ToolContext context) async {
    capturedContext = context;
    return Result.success('captured');
  }
}

void main() {
  test(
    'ToolInvoker invokes a registered tool and returns its Result',
    () async {
      final tool = _FakeTool();
      final invoker = ToolInvoker(
        registry: ToolRegistry(tools: {tool.id: tool}),
      );
      const toolCall = ToolCall(
        id: 'call_1',
        name: 'fake-tool',
        arguments: '{}',
      );

      final result = await invoker.invoke(toolCall);

      expect(result.success, isTrue);
      expect(result.message, 'executed');
    },
  );

  test('ToolInvoker returns Result.failure for an unknown tool id', () async {
    final invoker = ToolInvoker(registry: const ToolRegistry());
    const toolCall = ToolCall(id: 'call_1', name: 'missing', arguments: '{}');

    final result = await invoker.invoke(toolCall);

    expect(result.success, isFalse);
    expect(result.message, contains('missing'));
  });

  test(
    'ToolInvoker catches tool exceptions and returns Result.failure',
    () async {
      final tool = _ThrowingTool();
      final invoker = ToolInvoker(
        registry: ToolRegistry(tools: {tool.id: tool}),
      );
      const toolCall = ToolCall(
        id: 'call_1',
        name: 'throwing-tool',
        arguments: '{}',
      );

      final result = await invoker.invoke(toolCall);

      expect(result.success, isFalse);
      expect(result.message, contains('tool boom'));
    },
  );

  test('ToolInvoker passes a ToolContext with the invoked toolId', () async {
    final tool = _CapturingTool();
    final invoker = ToolInvoker(registry: ToolRegistry(tools: {tool.id: tool}));
    const toolCall = ToolCall(
      id: 'call_1',
      name: 'capturing-tool',
      arguments: '{}',
    );

    await invoker.invoke(toolCall);

    expect(tool.capturedContext, isNotNull);
    expect(tool.capturedContext!.toolId, 'capturing-tool');
  });

  test('ToolInvoker locates tools using toolCall.name, ignoring id', () async {
    final tool = _FakeTool();
    final invoker = ToolInvoker(registry: ToolRegistry(tools: {tool.id: tool}));
    const toolCall = ToolCall(
      id: 'call_unrelated_to_lookup',
      name: 'fake-tool',
      arguments: '{}',
    );

    final result = await invoker.invoke(toolCall);

    expect(result.success, isTrue);
    expect(result.message, 'executed');
  });
}
