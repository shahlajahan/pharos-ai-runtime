import 'package:pharos_ai_runtime/tools/models/tool.dart';
import 'package:pharos_ai_runtime/tools/models/tool_capability.dart';
import 'package:pharos_ai_runtime/tools/models/tool_id.dart';
import 'package:pharos_ai_runtime/tools/models/tool_request.dart';
import 'package:pharos_ai_runtime/tools/models/tool_status.dart';
import 'package:pharos_ai_runtime/tools/runtime/tool_selector.dart';
import 'package:test/test.dart';

Tool _tool(
  String id, {
  ToolStatus status = ToolStatus.available,
  Set<ToolCapability>? capabilities,
  Map<String, Object> metadata = const {},
}) => Tool(
  id: ToolId(id),
  name: id,
  description: '',
  status: status,
  capabilities: capabilities ?? {const ToolCapability('web-search')},
  supportedOperations: const ['search'],
  metadata: metadata,
);

ToolRequest _request({Set<ToolCapability>? requestedCapabilities}) =>
    ToolRequest(
      taskId: 'task-1',
      requestedCapabilities:
          requestedCapabilities ?? {const ToolCapability('web-search')},
      operation: 'search',
      parameters: const {},
      timeout: const Duration(seconds: 5),
      metadata: const {},
    );

void main() {
  const selector = ToolSelector();

  test('select() returns null when no tool matches the requested '
      'capability', () {
    final tools = [
      _tool('git', capabilities: {const ToolCapability('git')}),
    ];

    expect(selector.select(_request(), tools), isNull);
  });

  test('select() ignores offline and disabled tools', () {
    final tools = [
      _tool('offline-search', status: ToolStatus.offline),
      _tool('disabled-search', status: ToolStatus.disabled),
    ];

    expect(selector.select(_request(), tools), isNull);
  });

  test('select() prefers the tool with the higher capability match '
      'score', () {
    final partial = _tool(
      'partial',
      capabilities: {const ToolCapability('web-search')},
    );
    final full = _tool(
      'full',
      capabilities: {
        const ToolCapability('web-search'),
        const ToolCapability('browser'),
      },
    );

    final selected = selector.select(
      _request(
        requestedCapabilities: {
          const ToolCapability('web-search'),
          const ToolCapability('browser'),
        },
      ),
      [partial, full],
    );

    expect(selected?.id.value, 'full');
  });

  test('select() prefers available over busy when capability scores tie', () {
    final busy = _tool('busy', status: ToolStatus.busy);
    final available = _tool('available', status: ToolStatus.available);

    final selected = selector.select(_request(), [busy, available]);

    expect(selected?.id.value, 'available');
  });

  test('select() prefers higher metadata priority when otherwise tied', () {
    final lowPriority = _tool('low', metadata: const {'priority': 1});
    final highPriority = _tool('high', metadata: const {'priority': 5});

    final selected = selector.select(_request(), [lowPriority, highPriority]);

    expect(selected?.id.value, 'high');
  });

  test('select() prefers lower metadata cost when otherwise tied', () {
    final cheap = _tool('cheap', metadata: const {'cost': 1});
    final expensive = _tool('expensive', metadata: const {'cost': 10});

    final selected = selector.select(_request(), [expensive, cheap]);

    expect(selected?.id.value, 'cheap');
  });

  test('select() prefers lower metadata latency when otherwise tied', () {
    final slow = _tool('slow', metadata: const {'latencyMs': 500});
    final fast = _tool('fast', metadata: const {'latencyMs': 10});

    final selected = selector.select(_request(), [slow, fast]);

    expect(selected?.id.value, 'fast');
  });

  test('rank() returns every eligible candidate as a fallback chain, '
      'best first', () {
    final worse = _tool('worse', metadata: const {'priority': 1});
    final better = _tool('better', metadata: const {'priority': 5});

    final ranked = selector.rank(_request(), [worse, better]);

    expect(ranked.map((t) => t.id.value), ['better', 'worse']);
  });

  test('is deterministic for the same inputs', () {
    final tools = [
      _tool('a'),
      _tool('b', metadata: const {'priority': 2}),
    ];

    expect(
      selector.select(_request(), tools)?.id.value,
      selector.select(_request(), tools)?.id.value,
    );
  });
}
