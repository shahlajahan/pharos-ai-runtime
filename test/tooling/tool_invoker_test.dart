import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/tooling/tool.dart';
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
  test('ToolInvoker invokes a registered tool and returns its Result', () async {
    final tool = _FakeTool();
    final invoker = ToolInvoker(
      registry: ToolRegistry(tools: {tool.id: tool}),
    );

    final result = await invoker.invoke('fake-tool');

    expect(result.success, isTrue);
    expect(result.message, 'executed');
  });

  test('ToolInvoker returns Result.failure for an unknown tool id', () async {
    final invoker = ToolInvoker(registry: const ToolRegistry());

    final result = await invoker.invoke('missing');

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

      final result = await invoker.invoke('throwing-tool');

      expect(result.success, isFalse);
      expect(result.message, contains('tool boom'));
    },
  );

  test('ToolInvoker passes a ToolContext with the invoked toolId', () async {
    final tool = _CapturingTool();
    final invoker = ToolInvoker(
      registry: ToolRegistry(tools: {tool.id: tool}),
    );

    await invoker.invoke('capturing-tool');

    expect(tool.capturedContext, isNotNull);
    expect(tool.capturedContext!.toolId, 'capturing-tool');
  });
}
