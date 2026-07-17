import 'package:pharos_ai_runtime/models/conversation.dart';
import 'package:pharos_ai_runtime/tooling/tool_call.dart';
import 'package:test/test.dart';

void main() {
  test('Conversation stores messages in order', () {
    const systemMessage = SystemMessage(
      content: 'You are a helpful assistant.',
    );
    const userMessage = UserMessage(content: 'What is the capital of France?');
    const conversation = Conversation(messages: [systemMessage, userMessage]);

    expect(conversation.messages, [systemMessage, userMessage]);
  });

  test('Conversation defaults to an empty message list', () {
    const conversation = Conversation();

    expect(conversation.messages, isEmpty);
  });

  test('SystemMessage preserves its content', () {
    const message = SystemMessage(content: 'You are a helpful assistant.');

    expect(message.content, 'You are a helpful assistant.');
  });

  test('UserMessage preserves its content', () {
    const message = UserMessage(content: 'What is the capital of France?');

    expect(message.content, 'What is the capital of France?');
  });

  test('AssistantMessage preserves its content for a normal response', () {
    const message = AssistantMessage(
      content: 'Paris is the capital of France.',
    );

    expect(message.content, 'Paris is the capital of France.');
    expect(message.toolCalls, isEmpty);
  });

  test('AssistantMessage preserves toolCalls for a tool-calling response', () {
    const toolCalls = [
      ToolCall(id: 'call_1', name: 'search', arguments: '{"query":"Paris"}'),
    ];
    const message = AssistantMessage(content: '', toolCalls: toolCalls);

    expect(message.content, '');
    expect(message.toolCalls, toolCalls);
  });

  test('ToolMessage preserves toolCallId, toolName, and content', () {
    const message = ToolMessage(
      toolCallId: 'call_1',
      toolName: 'search',
      content: 'Paris is the capital of France.',
    );

    expect(message.toolCallId, 'call_1');
    expect(message.toolName, 'search');
    expect(message.content, 'Paris is the capital of France.');
  });
}
