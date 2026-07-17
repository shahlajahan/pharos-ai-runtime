import 'package:pharos_ai_runtime/models/conversation.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/tooling/tool_definition.dart';
import 'package:pharos_ai_runtime/tooling/tool_output.dart';
import 'package:test/test.dart';

void main() {
  test('ModelRequest stores the supplied Conversation', () {
    const conversation = Conversation(
      messages: [
        SystemMessage(content: 'You are a helpful assistant.'),
        UserMessage(content: 'What is the capital of France?'),
      ],
    );
    const request = ModelRequest(conversation: conversation);

    expect(request.conversation, same(conversation));
  });

  test('ModelRequest supports an empty Conversation', () {
    const request = ModelRequest(conversation: Conversation());

    expect(request.conversation.messages, isEmpty);
  });

  test('ModelRequest defaults to an empty tool list', () {
    const request = ModelRequest(conversation: Conversation());

    expect(request.tools, isEmpty);
  });

  test('ModelRequest preserves the given tool definitions', () {
    const tools = [
      ToolDefinition(id: 'search', description: 'Search the web.'),
      ToolDefinition(id: 'calculator', description: 'Evaluate math.'),
    ];
    const request = ModelRequest(conversation: Conversation(), tools: tools);

    expect(request.tools, tools);
  });

  test('ModelRequest defaults to an empty toolOutputs list', () {
    const request = ModelRequest(conversation: Conversation());

    expect(request.toolOutputs, isEmpty);
  });

  test('ModelRequest preserves the given toolOutputs', () {
    const toolOutputs = [
      ToolOutput(
        toolCallId: 'call_1',
        toolName: 'search',
        success: true,
        content: 'Paris.',
      ),
    ];
    const request = ModelRequest(
      conversation: Conversation(),
      toolOutputs: toolOutputs,
    );

    expect(request.toolOutputs, toolOutputs);
  });

  test('ModelRequest is immutable', () {
    const a = ModelRequest(conversation: Conversation());
    const b = ModelRequest(conversation: Conversation());

    // Two const instances with equal field values are canonicalized to the
    // same object by Dart, which is only possible because the constructor
    // is const and every field is final.
    expect(identical(a, b), isTrue);
  });
}
