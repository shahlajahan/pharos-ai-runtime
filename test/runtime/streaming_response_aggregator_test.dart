import 'package:pharos_ai_runtime/models/streaming_response.dart';
import 'package:pharos_ai_runtime/runtime/streaming_response_aggregator.dart';
import 'package:pharos_ai_runtime/tooling/tool_call.dart';
import 'package:test/test.dart';

class _FakeStreamingResponse implements StreamingResponse {
  const _FakeStreamingResponse(this.stream);

  @override
  final Stream<ModelResponseChunk> stream;
}

void main() {
  test('aggregate() accumulates multiple textDelta chunks into the final '
      'ModelResponse.text', () async {
    final aggregator = StreamingResponseAggregator();
    final streamingResponse = _FakeStreamingResponse(
      Stream.fromIterable(const [
        ModelResponseChunk(textDelta: 'Hello'),
        ModelResponseChunk(textDelta: ' world'),
        ModelResponseChunk(isFinished: true),
      ]),
    );

    final response = await aggregator.aggregate(streamingResponse);

    expect(response.text, 'Hello world');
  });

  test('aggregate() accumulates toolCalls chunks into the final '
      'ModelResponse.toolCalls, preserving order', () async {
    final aggregator = StreamingResponseAggregator();
    const toolCall1 = ToolCall(id: 'call_1', name: 'search', arguments: '{}');
    const toolCall2 = ToolCall(
      id: 'call_2',
      name: 'calculator',
      arguments: '{}',
    );
    final streamingResponse = _FakeStreamingResponse(
      Stream.fromIterable(const [
        ModelResponseChunk(toolCalls: [toolCall1]),
        ModelResponseChunk(toolCalls: [toolCall2]),
        ModelResponseChunk(isFinished: true),
      ]),
    );

    final response = await aggregator.aggregate(streamingResponse);

    expect(response.toolCalls, [toolCall1, toolCall2]);
  });

  test('aggregate() stops consuming chunks once isFinished is true', () async {
    final aggregator = StreamingResponseAggregator();
    final streamingResponse = _FakeStreamingResponse(
      Stream.fromIterable(const [
        ModelResponseChunk(textDelta: 'Hello'),
        ModelResponseChunk(isFinished: true),
        ModelResponseChunk(textDelta: 'ignored'),
      ]),
    );

    final response = await aggregator.aggregate(streamingResponse);

    expect(response.text, 'Hello');
  });

  test('aggregate() returns an empty ModelResponse when the stream finishes '
      'immediately', () async {
    final aggregator = StreamingResponseAggregator();
    final streamingResponse = _FakeStreamingResponse(
      Stream.fromIterable(const [ModelResponseChunk(isFinished: true)]),
    );

    final response = await aggregator.aggregate(streamingResponse);

    expect(response.text, '');
    expect(response.toolCalls, isEmpty);
  });

  test('aggregate() combines text and tool calls from separate chunks into '
      'one final ModelResponse', () async {
    final aggregator = StreamingResponseAggregator();
    const toolCall = ToolCall(id: 'call_1', name: 'search', arguments: '{}');
    final streamingResponse = _FakeStreamingResponse(
      Stream.fromIterable(const [
        ModelResponseChunk(textDelta: 'Hello'),
        ModelResponseChunk(textDelta: ' world'),
        ModelResponseChunk(toolCalls: [toolCall]),
        ModelResponseChunk(isFinished: true),
      ]),
    );

    final response = await aggregator.aggregate(streamingResponse);

    expect(response.text, 'Hello world');
    expect(response.toolCalls, [toolCall]);
  });
}
