import 'package:pharos_ai_runtime/models/conversation.dart';
import 'package:pharos_ai_runtime/models/model_provider.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/models/model_response.dart';
import 'package:test/test.dart';

class _FakeModelProvider extends ModelProvider {
  @override
  Future<ModelResponse> generate(ModelRequest request) async {
    return const ModelResponse(text: 'Paris is the capital of France.');
  }
}

void main() {
  test(
    'ModelProvider exposes generate(request) returning a ModelResponse',
    () async {
      final provider = _FakeModelProvider();
      const request = ModelRequest(
        conversation: Conversation(
          messages: [
            SystemMessage(content: 'You are a helpful assistant.'),
            UserMessage(content: 'What is the capital of France?'),
          ],
        ),
      );

      final response = await provider.generate(request);

      expect(response.text, 'Paris is the capital of France.');
    },
  );
}
