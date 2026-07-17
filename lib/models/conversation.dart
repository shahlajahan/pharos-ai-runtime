import 'package:pharos_ai_runtime/tooling/tool_call.dart';

class Conversation {
  const Conversation({this.messages = const []});

  final List<Message> messages;
}

abstract class Message {
  const Message();
}

class SystemMessage extends Message {
  const SystemMessage({required this.content});

  final String content;
}

class UserMessage extends Message {
  const UserMessage({required this.content});

  final String content;
}

class AssistantMessage extends Message {
  const AssistantMessage({required this.content, this.toolCalls = const []});

  final String content;

  /// Empty when the assistant is replying normally.
  final List<ToolCall> toolCalls;
}

class ToolMessage extends Message {
  const ToolMessage({
    required this.toolCallId,
    required this.toolName,
    required this.content,
  });

  final String toolCallId;
  final String toolName;
  final String content;
}
