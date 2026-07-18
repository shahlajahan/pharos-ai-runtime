import 'package:pharos_ai_runtime/models/streaming_response.dart';
import 'package:pharos_ai_runtime/runtime/tool_call_reconstructor.dart';
import 'package:pharos_ai_runtime/tooling/tool_call.dart';
import 'package:test/test.dart';

void main() {
  test('complete() returns an empty list when nothing was observed', () {
    final reconstructor = ToolCallReconstructor();

    expect(reconstructor.complete(), isEmpty);
  });

  test('observe() ignores chunks with no toolCalls', () {
    final reconstructor = ToolCallReconstructor();

    reconstructor.observe(const ModelResponseChunk(textDelta: 'Hello'));
    reconstructor.observe(const ModelResponseChunk(isFinished: true));

    expect(reconstructor.complete(), isEmpty);
  });

  test(
    'observe() reconstructs a single ToolCall delivered in one fragment',
    () {
      final reconstructor = ToolCallReconstructor();

      reconstructor.observe(
        const ModelResponseChunk(
          toolCalls: [
            ToolCall(id: 'call_1', name: 'search', arguments: '{"q":"hi"}'),
          ],
        ),
      );

      final result = reconstructor.complete();

      expect(result, hasLength(1));
      expect(result[0].id, 'call_1');
      expect(result[0].name, 'search');
      expect(result[0].arguments, '{"q":"hi"}');
    },
  );

  test('observe() merges argument fragments that repeat the same id', () {
    final reconstructor = ToolCallReconstructor();

    reconstructor.observe(
      const ModelResponseChunk(
        toolCalls: [ToolCall(id: 'call_1', name: 'search', arguments: '{"q":')],
      ),
    );
    reconstructor.observe(
      const ModelResponseChunk(
        toolCalls: [ToolCall(id: 'call_1', name: '', arguments: '"hi"}')],
      ),
    );

    final result = reconstructor.complete();

    expect(result, hasLength(1));
    expect(result[0].id, 'call_1');
    expect(result[0].name, 'search');
    expect(result[0].arguments, '{"q":"hi"}');
  });

  test('observe() merges argument fragments that omit the id, attaching them '
      'to the most recently seen ToolCall', () {
    final reconstructor = ToolCallReconstructor();

    reconstructor.observe(
      const ModelResponseChunk(
        toolCalls: [ToolCall(id: 'call_1', name: 'search', arguments: '{')],
      ),
    );
    reconstructor.observe(
      const ModelResponseChunk(
        toolCalls: [ToolCall(id: '', name: '', arguments: '"q":')],
      ),
    );
    reconstructor.observe(
      const ModelResponseChunk(
        toolCalls: [ToolCall(id: '', name: '', arguments: '"hi"}')],
      ),
    );

    final result = reconstructor.complete();

    expect(result, hasLength(1));
    expect(result[0].id, 'call_1');
    expect(result[0].name, 'search');
    expect(result[0].arguments, '{"q":"hi"}');
  });

  test('observe() reconstructs multiple distinct ToolCalls, preserving '
      'first-seen order', () {
    final reconstructor = ToolCallReconstructor();

    reconstructor.observe(
      const ModelResponseChunk(
        toolCalls: [ToolCall(id: 'call_1', name: 'search', arguments: '{')],
      ),
    );
    reconstructor.observe(
      const ModelResponseChunk(
        toolCalls: [ToolCall(id: '', name: '', arguments: '"q":"hi"}')],
      ),
    );
    reconstructor.observe(
      const ModelResponseChunk(
        toolCalls: [
          ToolCall(id: 'call_2', name: 'calculator', arguments: '{"x":'),
        ],
      ),
    );
    reconstructor.observe(
      const ModelResponseChunk(
        toolCalls: [ToolCall(id: '', name: '', arguments: '1}')],
      ),
    );

    final result = reconstructor.complete();

    expect(result, hasLength(2));
    expect(result[0].id, 'call_1');
    expect(result[0].arguments, '{"q":"hi"}');
    expect(result[1].id, 'call_2');
    expect(result[1].arguments, '{"x":1}');
  });

  test('observe() drops a continuation fragment that arrives before any '
      'ToolCall id has been seen', () {
    final reconstructor = ToolCallReconstructor();

    reconstructor.observe(
      const ModelResponseChunk(
        toolCalls: [ToolCall(id: '', name: '', arguments: 'orphaned')],
      ),
    );

    expect(reconstructor.complete(), isEmpty);
  });

  test('observe() interleaves fragments for two ToolCalls across chunks '
      'without losing or mixing up either one', () {
    final reconstructor = ToolCallReconstructor();

    reconstructor.observe(
      const ModelResponseChunk(
        toolCalls: [ToolCall(id: 'call_1', name: 'search', arguments: 'a')],
      ),
    );
    reconstructor.observe(
      const ModelResponseChunk(
        toolCalls: [ToolCall(id: 'call_2', name: 'calculator', arguments: 'x')],
      ),
    );
    reconstructor.observe(
      const ModelResponseChunk(
        toolCalls: [ToolCall(id: 'call_1', name: '', arguments: 'b')],
      ),
    );
    reconstructor.observe(
      const ModelResponseChunk(
        toolCalls: [ToolCall(id: 'call_2', name: '', arguments: 'y')],
      ),
    );

    final result = reconstructor.complete();

    expect(result, hasLength(2));
    expect(result[0].id, 'call_1');
    expect(result[0].arguments, 'ab');
    expect(result[1].id, 'call_2');
    expect(result[1].arguments, 'xy');
  });

  test('drainCompleted() returns nothing while only one ToolCall is in '
      'progress', () {
    final reconstructor = ToolCallReconstructor();

    reconstructor.observe(
      const ModelResponseChunk(
        toolCalls: [ToolCall(id: 'call_1', name: 'search', arguments: '{')],
      ),
    );

    expect(reconstructor.drainCompleted(), isEmpty);

    reconstructor.observe(
      const ModelResponseChunk(
        toolCalls: [ToolCall(id: '', name: '', arguments: '}')],
      ),
    );

    expect(reconstructor.drainCompleted(), isEmpty);
  });

  test('drainCompleted() returns a ToolCall as soon as a fragment for a new '
      'id arrives', () {
    final reconstructor = ToolCallReconstructor();

    reconstructor.observe(
      const ModelResponseChunk(
        toolCalls: [
          ToolCall(id: 'call_1', name: 'search', arguments: '{"q":"hi"}'),
        ],
      ),
    );

    expect(reconstructor.drainCompleted(), isEmpty);

    reconstructor.observe(
      const ModelResponseChunk(
        toolCalls: [
          ToolCall(id: 'call_2', name: 'calculator', arguments: '{"x":1}'),
        ],
      ),
    );

    final completed = reconstructor.drainCompleted();

    expect(completed, hasLength(1));
    expect(completed[0].id, 'call_1');
    expect(completed[0].name, 'search');
    expect(completed[0].arguments, '{"q":"hi"}');
  });

  test('drainCompleted() never returns the same ToolCall twice', () {
    final reconstructor = ToolCallReconstructor();

    reconstructor.observe(
      const ModelResponseChunk(
        toolCalls: [ToolCall(id: 'call_1', name: 'search', arguments: '{}')],
      ),
    );
    reconstructor.observe(
      const ModelResponseChunk(
        toolCalls: [
          ToolCall(id: 'call_2', name: 'calculator', arguments: '{}'),
        ],
      ),
    );

    expect(reconstructor.drainCompleted(), hasLength(1));
    expect(reconstructor.drainCompleted(), isEmpty);
  });

  test('drainRemaining() returns the still in-progress ToolCall once the '
      'stream ends', () {
    final reconstructor = ToolCallReconstructor();

    reconstructor.observe(
      const ModelResponseChunk(
        toolCalls: [
          ToolCall(id: 'call_1', name: 'search', arguments: '{"q":"hi"}'),
        ],
      ),
    );

    expect(reconstructor.drainCompleted(), isEmpty);

    final remaining = reconstructor.drainRemaining();

    expect(remaining, hasLength(1));
    expect(remaining[0].id, 'call_1');
    expect(remaining[0].arguments, '{"q":"hi"}');
  });

  test('drainRemaining() returns nothing when nothing was observed', () {
    final reconstructor = ToolCallReconstructor();

    expect(reconstructor.drainRemaining(), isEmpty);
  });

  test('drainCompleted() then drainRemaining() together execute every '
      'ToolCall exactly once', () {
    final reconstructor = ToolCallReconstructor();

    reconstructor.observe(
      const ModelResponseChunk(
        toolCalls: [ToolCall(id: 'call_1', name: 'search', arguments: '{}')],
      ),
    );
    final firstDrain = reconstructor.drainCompleted();

    reconstructor.observe(
      const ModelResponseChunk(
        toolCalls: [
          ToolCall(id: 'call_2', name: 'calculator', arguments: '{}'),
        ],
      ),
    );
    final secondDrain = reconstructor.drainCompleted();
    final remaining = reconstructor.drainRemaining();

    expect(firstDrain, isEmpty);
    expect(secondDrain.map((c) => c.id), ['call_1']);
    expect(remaining.map((c) => c.id), ['call_2']);
  });
}
