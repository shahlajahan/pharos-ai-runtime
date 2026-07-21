import 'package:pharos_ai_runtime/tools/models/tool.dart';
import 'package:pharos_ai_runtime/tools/models/tool_capability.dart';
import 'package:pharos_ai_runtime/tools/models/tool_id.dart';
import 'package:pharos_ai_runtime/tools/models/tool_request.dart';
import 'package:pharos_ai_runtime/tools/models/tool_status.dart';
import 'package:pharos_ai_runtime/tools/registry/tool_registry.dart';
import 'package:pharos_ai_runtime/tools/runtime/tool_runtime.dart';
import 'package:test/test.dart';

Tool _tool(
  String id, {
  ToolStatus status = ToolStatus.available,
  Set<ToolCapability>? capabilities,
  List<String> supportedOperations = const ['search'],
  Map<String, Object> metadata = const {},
}) => Tool(
  id: ToolId(id),
  name: id,
  description: '',
  status: status,
  capabilities: capabilities ?? {const ToolCapability('web-search')},
  supportedOperations: supportedOperations,
  metadata: metadata,
);

ToolRequest _request({
  Set<ToolCapability>? requestedCapabilities,
  String operation = 'search',
  Duration timeout = const Duration(seconds: 5),
}) => ToolRequest(
  taskId: 'task-1',
  requestedCapabilities:
      requestedCapabilities ?? {const ToolCapability('web-search')},
  operation: operation,
  parameters: const {},
  timeout: timeout,
  metadata: const {},
);

void main() {
  test('invoke() returns a normalized, successful ToolResult when a '
      'registered tool matches the request', () {
    final registry = ToolRegistry()..register(_tool('web-search'));
    final runtime = ToolRuntime(registry: registry);

    final result = runtime.invoke(_request());

    expect(result.success, isTrue);
    expect(result.output, contains('web-search'));
    expect(result.errors, isEmpty);
    expect(result.executionTime, isNotNull);
  });

  test('invoke() reports missing tools when the registry is empty', () {
    final runtime = ToolRuntime(registry: ToolRegistry());

    final result = runtime.invoke(_request());

    expect(result.success, isFalse);
    expect(result.errors, isNotEmpty);
  });

  test('invoke() reports missing tools when none support the requested '
      'capability', () {
    final registry = ToolRegistry()
      ..register(
        _tool('git', capabilities: {const ToolCapability('git-commit')}),
      );
    final runtime = ToolRuntime(registry: registry);

    final result = runtime.invoke(_request());

    expect(result.success, isFalse);
    expect(result.errors, isNotEmpty);
  });

  test('invoke() rejects a non-positive timeout via the ToolResult, not '
      'an exception', () {
    final registry = ToolRegistry()..register(_tool('web-search'));
    final runtime = ToolRuntime(registry: registry);

    final result = runtime.invoke(_request(timeout: Duration.zero));

    expect(result.success, isFalse);
    expect(result.errors, isNotEmpty);
  });

  test('invoke() falls back to the next candidate when the best-ranked '
      'tool fails validation', () {
    // Both tools are eligible and capability-matching (so the selector
    // ranks them both), but the higher-priority one doesn't actually
    // support the requested operation, so the validator rejects it and
    // the runtime falls back to the next-ranked candidate.
    final registry = ToolRegistry()
      ..register(
        _tool(
          'unsupported-op-search',
          supportedOperations: const ['other-operation'],
          // Higher priority guarantees this candidate is ranked and
          // tried first, so the fallback path is actually exercised.
          metadata: const {'priority': 10},
        ),
      )
      ..register(_tool('working-search'));
    final runtime = ToolRuntime(registry: registry);

    final result = runtime.invoke(_request());

    expect(result.success, isTrue);
    expect(result.output, contains('working-search'));
    expect(result.warnings, isNotEmpty);
  });

  test('invoke() fails when every candidate fails validation, after '
      'trying each as a fallback', () {
    final registry = ToolRegistry()
      ..register(
        _tool('bad-op-a', supportedOperations: const ['other-operation']),
      )
      ..register(
        _tool('bad-op-b', supportedOperations: const ['other-operation']),
      );
    final runtime = ToolRuntime(registry: registry);

    final result = runtime.invoke(_request());

    expect(result.success, isFalse);
    expect(result.warnings, hasLength(2));
    expect(result.errors, isNotEmpty);
  });

  test('invoke() always returns the same normalized ToolResult shape, '
      'success or failure', () {
    final registry = ToolRegistry()..register(_tool('web-search'));
    final runtime = ToolRuntime(registry: registry);

    final success = runtime.invoke(_request());
    final failure = runtime.invoke(_request(operation: 'unsupported-op'));

    for (final result in [success, failure]) {
      expect(result.output, isA<String>());
      expect(result.structuredData, isA<Map<String, Object>>());
      expect(result.artifacts, isA<List<String>>());
      expect(result.warnings, isA<List<String>>());
      expect(result.errors, isA<List<String>>());
      expect(result.executionTime, isA<Duration>());
    }
  });

  test('is deterministic for the same inputs', () {
    final registry = ToolRegistry()..register(_tool('web-search'));
    final runtime = ToolRuntime(registry: registry);

    expect(
      runtime.invoke(_request()).success,
      runtime.invoke(_request()).success,
    );
  });
}
