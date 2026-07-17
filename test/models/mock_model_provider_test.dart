import 'package:pharos_ai_runtime/models/conversation.dart';
import 'package:pharos_ai_runtime/models/mock_model_provider.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/models/model_response.dart';
import 'package:test/test.dart';

void main() {
  const request = ModelRequest(
    conversation: Conversation(
      messages: [
        SystemMessage(content: 'You are a helpful assistant.'),
        UserMessage(content: 'What is the capital of France?'),
      ],
    ),
  );

  test('generate() returns a ModelResponse', () async {
    final response = await MockModelProvider().generate(request);

    expect(response, isA<ModelResponse>());
  });

  test('generate() returns "Mock response"', () async {
    final response = await MockModelProvider().generate(request);

    expect(response.text, 'Mock response');
  });

  test('generate() returns identical results across multiple calls', () async {
    final provider = MockModelProvider();

    final first = await provider.generate(request);
    final second = await provider.generate(
      const ModelRequest(
        conversation: Conversation(
          messages: [
            SystemMessage(content: 'A completely different prompt.'),
            UserMessage(content: 'A completely different question.'),
          ],
        ),
      ),
    );

    expect(first.text, second.text);
    expect(second.text, 'Mock response');
  });
}
