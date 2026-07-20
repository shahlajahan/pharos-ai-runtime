import 'dart:convert';

import 'package:pharos_ai_runtime/models/conversation.dart';
import 'package:pharos_ai_runtime/models/model_config.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/models/openai_client.dart';
import 'package:pharos_ai_runtime/models/openai_config.dart';
import 'package:pharos_ai_runtime/models/openai_exception.dart';
import 'package:pharos_ai_runtime/models/openai_result.dart';
import 'package:pharos_ai_runtime/models/streaming_response.dart';
import 'package:pharos_ai_runtime/network/http_transport.dart';
import 'package:pharos_ai_runtime/tooling/tool_call.dart';

class HttpOpenAIClient extends OpenAIClient {
  HttpOpenAIClient({required HttpTransport transport}) : _transport = transport;

  final HttpTransport _transport;

  /// Builds the chat completions endpoint from [baseUrl], the
  /// OpenAI-compatible API root (for example `https://openrouter.ai/api/v1`
  /// or `https://api.openai.com/v1`) — never the full endpoint itself.
  Uri _chatCompletionsUri(String baseUrl) {
    final root = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    return Uri.parse('$root/chat/completions');
  }

  @override
  Future<OpenAIResult> complete(
    ModelRequest request,
    ModelConfig modelConfig,
    OpenAIConfig openAiConfig,
  ) async {
    final uri = _chatCompletionsUri(openAiConfig.baseUrl);

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${openAiConfig.apiKey}',
      if (openAiConfig.organization != null)
        'OpenAI-Organization': openAiConfig.organization!,
    };

    final body = jsonEncode({
      'model': modelConfig.model,
      'temperature': modelConfig.temperature,
      'messages': _serializeConversation(request.conversation),
      if (request.tools.isNotEmpty)
        'tools': request.tools
            .map(
              (tool) => {
                'type': 'function',
                'function': {'name': tool.id, 'description': tool.description},
              },
            )
            .toList(),
    });

    final response = await _transport.post(
      uri: uri,
      headers: headers,
      body: body,
    );

    if (response.statusCode != 200) {
      String? errorMessage;

      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final error = decoded['error'];

        if (error is Map<String, dynamic> && error['message'] is String) {
          errorMessage = error['message'] as String;
        }
      } on FormatException {
        errorMessage = null;
      }

      throw OpenAIException(errorMessage ?? 'HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (decoded.containsKey('error')) {
      final error = decoded['error'] as Map<String, dynamic>;
      throw OpenAIException('OpenAI API error: ${error['message']}');
    }

    final choices = decoded['choices'] as List<dynamic>;
    final message =
        (choices[0] as Map<String, dynamic>)['message'] as Map<String, dynamic>;
    final rawContent = message['content'];
    final text = rawContent == null ? '' : rawContent as String;

    final rawToolCalls = message['tool_calls'] as List<dynamic>?;

    final toolCalls = rawToolCalls == null
        ? const <ToolCall>[]
        : rawToolCalls.map((entry) {
            final toolCall = entry as Map<String, dynamic>;
            final function = toolCall['function'] as Map<String, dynamic>;

            return ToolCall(
              id: toolCall['id'] as String,
              name: function['name'] as String,
              arguments: function['arguments'] as String,
            );
          }).toList();

    return OpenAIResult(text: text, toolCalls: toolCalls);
  }

  Future<StreamingResponse> stream(
    ModelRequest request,
    ModelConfig modelConfig,
    OpenAIConfig openAiConfig,
  ) async {
    final uri = _chatCompletionsUri(openAiConfig.baseUrl);

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${openAiConfig.apiKey}',
      if (openAiConfig.organization != null)
        'OpenAI-Organization': openAiConfig.organization!,
    };

    final body = jsonEncode({
      'model': modelConfig.model,
      'temperature': modelConfig.temperature,
      'stream': true,
      'messages': _serializeConversation(request.conversation),
      if (request.tools.isNotEmpty)
        'tools': request.tools
            .map(
              (tool) => {
                'type': 'function',
                'function': {'name': tool.id, 'description': tool.description},
              },
            )
            .toList(),
    });

    final response = await _transport.post(
      uri: uri,
      headers: headers,
      body: body,
    );

    return _OpenAIStreamingResponse(_parseSse(response.body));
  }

  List<Map<String, dynamic>> _serializeConversation(Conversation conversation) {
    final conversationMessages = <Map<String, dynamic>>[];

    for (final message in conversation.messages) {
      if (message is SystemMessage) {
        conversationMessages.add({
          'role': 'system',
          'content': message.content,
        });
      } else if (message is UserMessage) {
        conversationMessages.add({'role': 'user', 'content': message.content});
      } else if (message is AssistantMessage) {
        final assistantMessage = <String, dynamic>{
          'role': 'assistant',
          'content': message.content,
        };

        if (message.toolCalls.isNotEmpty) {
          assistantMessage['tool_calls'] = message.toolCalls
              .map(
                (toolCall) => {
                  'id': toolCall.id,
                  'type': 'function',
                  'function': {
                    'name': toolCall.name,
                    'arguments': toolCall.arguments,
                  },
                },
              )
              .toList();
        }

        conversationMessages.add(assistantMessage);
      } else if (message is ToolMessage) {
        conversationMessages.add({
          'role': 'tool',
          'tool_call_id': message.toolCallId,
          'content': message.content,
        });
      }
    }

    return conversationMessages;
  }

  Stream<ModelResponseChunk> _parseSse(String body) async* {
    for (final rawLine in const LineSplitter().convert(body)) {
      final line = rawLine.trim();

      if (!line.startsWith('data:')) {
        continue;
      }

      final payload = line.substring('data:'.length).trim();

      if (payload == '[DONE]') {
        yield const ModelResponseChunk(isFinished: true);
        return;
      }

      final decoded = jsonDecode(payload) as Map<String, dynamic>;
      final choices = decoded['choices'] as List<dynamic>;
      final delta =
          (choices[0] as Map<String, dynamic>)['delta'] as Map<String, dynamic>;

      final content = delta['content'];
      final rawToolCalls = delta['tool_calls'];

      if (content == null && rawToolCalls == null) {
        continue;
      }

      yield ModelResponseChunk(
        textDelta: content as String?,
        toolCalls: rawToolCalls == null
            ? null
            : (rawToolCalls as List<dynamic>).map((entry) {
                final toolCall = entry as Map<String, dynamic>;
                final function = toolCall['function'] as Map<String, dynamic>?;

                return ToolCall(
                  id: toolCall['id'] as String? ?? '',
                  name: function?['name'] as String? ?? '',
                  arguments: function?['arguments'] as String? ?? '',
                );
              }).toList(),
      );
    }
  }
}

class _OpenAIStreamingResponse implements StreamingResponse {
  const _OpenAIStreamingResponse(this.stream);

  @override
  final Stream<ModelResponseChunk> stream;
}
