import 'dart:convert';

import 'package:pharos_ai_runtime/models/model_config.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/models/openai_client.dart';
import 'package:pharos_ai_runtime/models/openai_config.dart';
import 'package:pharos_ai_runtime/models/openai_exception.dart';
import 'package:pharos_ai_runtime/models/openai_result.dart';
import 'package:pharos_ai_runtime/network/http_transport.dart';

class HttpOpenAIClient extends OpenAIClient {
  HttpOpenAIClient({required HttpTransport transport}) : _transport = transport;

  final HttpTransport _transport;

  @override
  Future<OpenAIResult> complete(
    ModelRequest request,
    ModelConfig modelConfig,
    OpenAIConfig openAiConfig,
  ) async {
    final uri = Uri.parse(openAiConfig.baseUrl);

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${openAiConfig.apiKey}',
      if (openAiConfig.organization != null)
        'OpenAI-Organization': openAiConfig.organization!,
    };

    final body = jsonEncode({
      'model': modelConfig.model,
      'temperature': modelConfig.temperature,
      'messages': [
        {'role': 'system', 'content': request.systemPrompt},
        {'role': 'user', 'content': request.userPrompt},
      ],
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
    final text = message['content'] as String;

    return OpenAIResult(text: text);
  }
}
