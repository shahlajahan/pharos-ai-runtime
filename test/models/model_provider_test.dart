import 'package:pharos_ai_runtime/models/conversation.dart';
import 'package:pharos_ai_runtime/models/model_config.dart';
import 'package:pharos_ai_runtime/models/model_provider.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/models/model_response.dart';
import 'package:pharos_ai_runtime/models/streaming_response.dart';
import 'package:pharos_ai_runtime/tooling/tool_call.dart';
import 'package:test/test.dart';

class _FakeModelProvider extends ModelProvider {
  @override
  Future<ModelResponse> generate(ModelRequest request) async {
    return const ModelResponse(text: 'Paris is the capital of France.');
  }
}

class _FakeStreamingResponse implements StreamingResponse {
  const _FakeStreamingResponse(this.stream);

  @override
  final Stream<ModelResponseChunk> stream;
}

class _StreamingModelProvider extends ModelProvider {
  @override
  Future<ModelResponse> generate(ModelRequest request) async {
    return const ModelResponse(text: 'Paris is the capital of France.');
  }

  @override
  Future<StreamingResponse> stream(
    ModelRequest request,
    ModelConfig modelConfig,
  ) async {
    return _FakeStreamingResponse(
      Stream.fromIterable(const [
        ModelResponseChunk(textDelta: 'Paris'),
        ModelResponseChunk(isFinished: true),
      ]),
    );
  }
}

void main() {
  const request = ModelRequest(
    conversation: Conversation(
      messages: [
        SystemMessage(content: 'You are a helpful assistant.'),
        UserMessage(content: 'What is the capital of France?'),
      ],
    ),
  );
  const modelConfig = ModelConfig(model: 'gpt-4', temperature: 0.7);

  test(
    'ModelProvider exposes generate(request) returning a ModelResponse',
    () async {
      final provider = _FakeModelProvider();

      final response = await provider.generate(request);

      expect(response.text, 'Paris is the capital of France.');
    },
  );

  test('ModelProvider.stream() throws UnimplementedError by default', () async {
    final provider = _FakeModelProvider();

    expect(
      () => provider.stream(request, modelConfig),
      throwsA(isA<UnimplementedError>()),
    );
  });

  test('ModelProvider.stream() can be overridden to return a StreamingResponse '
      'exposing Stream<ModelResponseChunk>', () async {
    final provider = _StreamingModelProvider();

    final streamingResponse = await provider.stream(request, modelConfig);
    final chunks = await streamingResponse.stream.toList();

    expect(chunks, hasLength(2));
    expect(chunks[0].textDelta, 'Paris');
    expect(chunks[0].isFinished, isFalse);
    expect(chunks[1].isFinished, isTrue);
  });

  test('ModelResponseChunk defaults toolCalls and textDelta to null, and '
      'isFinished to false', () {
    const chunk = ModelResponseChunk();

    expect(chunk.textDelta, isNull);
    expect(chunk.toolCalls, isNull);
    expect(chunk.isFinished, isFalse);
  });

  test('ModelResponseChunk stores textDelta, toolCalls, and isFinished', () {
    const toolCalls = [ToolCall(id: 'call_1', name: 'search', arguments: '{}')];
    const chunk = ModelResponseChunk(
      textDelta: 'Paris',
      toolCalls: toolCalls,
      isFinished: true,
    );

    expect(chunk.textDelta, 'Paris');
    expect(chunk.toolCalls, same(toolCalls));
    expect(chunk.isFinished, isTrue);
  });

  test('complete() remains unchanged and unaffected by stream()', () async {
    final provider = _StreamingModelProvider();

    final response = await provider.generate(request);

    expect(response.text, 'Paris is the capital of France.');
  });
}
