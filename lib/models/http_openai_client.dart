import 'dart:convert';

import 'package:pharos_ai_runtime/models/model_config.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/models/openai_client.dart';
import 'package:pharos_ai_runtime/models/openai_config.dart';
import 'package:pharos_ai_runtime/models/openai_result.dart';
import 'package:pharos_ai_runtime/network/http_transport.dart';

class HttpOpenAIClient extends OpenAIClient {
  HttpOpenAIClient({required HttpTransport transport})
    : _transport = transport;

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
    });

    final responseBody = await _transport.post(
      uri: uri,
      headers: headers,
      body: body,
    );

    final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
    final choices = decoded['choices'] as List<dynamic>;
    final message =
        (choices[0] as Map<String, dynamic>)['message']
            as Map<String, dynamic>;
    final text = message['content'] as String;

    return OpenAIResult(text: text);
  }
}
