import 'dart:convert';

import 'package:pharos_ai_runtime/models/conversation.dart';
import 'package:pharos_ai_runtime/models/http_openai_client.dart';
import 'package:pharos_ai_runtime/models/model_config.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/models/openai_config.dart';
import 'package:pharos_ai_runtime/models/openai_exception.dart';
import 'package:pharos_ai_runtime/network/http_transport.dart';
import 'package:pharos_ai_runtime/network/http_transport_response.dart';
import 'package:pharos_ai_runtime/tooling/tool_call.dart';
import 'package:pharos_ai_runtime/tooling/tool_definition.dart';
import 'package:pharos_ai_runtime/tooling/tool_output.dart';
import 'package:test/test.dart';

class _FakeHttpTransport extends HttpTransport {
  Uri? capturedUri;
  Map<String, String>? capturedHeaders;
  String? capturedBody;
  String responseBody = '{"choices": [{"message": {"content": "Paris."}}]}';
  int statusCode = 200;

  @override
  Future<HttpTransportResponse> post({
    required Uri uri,
    required Map<String, String> headers,
    required String body,
  }) async {
    capturedUri = uri;
    capturedHeaders = headers;
    capturedBody = body;

    return HttpTransportResponse(
      statusCode: statusCode,
      headers: const {},
      body: responseBody,
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

  test('complete() includes the Authorization header', () async {
    final transport = _FakeHttpTransport();
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );

    await client.complete(request, modelConfig, openAiConfig);

    expect(transport.capturedHeaders!['Authorization'], 'Bearer sk-test');
  });

  test(
    'complete() includes the OpenAI-Organization header when provided',
    () async {
      final transport = _FakeHttpTransport();
      final client = HttpOpenAIClient(transport: transport);
      const openAiConfig = OpenAIConfig(
        apiKey: 'sk-test',
        baseUrl: 'https://api.openai.com/v1/chat/completions',
        organization: 'org-test',
      );

      await client.complete(request, modelConfig, openAiConfig);

      expect(transport.capturedHeaders!['OpenAI-Organization'], 'org-test');
    },
  );

  test(
    'complete() omits the OpenAI-Organization header when not provided',
    () async {
      final transport = _FakeHttpTransport();
      final client = HttpOpenAIClient(transport: transport);
      const openAiConfig = OpenAIConfig(
        apiKey: 'sk-test',
        baseUrl: 'https://api.openai.com/v1/chat/completions',
      );

      await client.complete(request, modelConfig, openAiConfig);

      expect(
        transport.capturedHeaders!.containsKey('OpenAI-Organization'),
        isFalse,
      );
    },
  );

  test('complete() encodes model correctly', () async {
    final transport = _FakeHttpTransport();
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );

    await client.complete(request, modelConfig, openAiConfig);

    final decoded = jsonDecode(transport.capturedBody!) as Map<String, dynamic>;
    expect(decoded['model'], 'gpt-4');
  });

  test('complete() encodes temperature correctly', () async {
    final transport = _FakeHttpTransport();
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );

    await client.complete(request, modelConfig, openAiConfig);

    final decoded = jsonDecode(transport.capturedBody!) as Map<String, dynamic>;
    expect(decoded['temperature'], 0.7);
  });

  test('complete() encodes the system message correctly', () async {
    final transport = _FakeHttpTransport();
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );

    await client.complete(request, modelConfig, openAiConfig);

    final decoded = jsonDecode(transport.capturedBody!) as Map<String, dynamic>;
    final messages = decoded['messages'] as List<dynamic>;
    final systemMessage = messages[0] as Map<String, dynamic>;

    expect(systemMessage['role'], 'system');
    expect(systemMessage['content'], 'You are a helpful assistant.');
  });

  test('complete() encodes the user message correctly', () async {
    final transport = _FakeHttpTransport();
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );

    await client.complete(request, modelConfig, openAiConfig);

    final decoded = jsonDecode(transport.capturedBody!) as Map<String, dynamic>;
    final messages = decoded['messages'] as List<dynamic>;
    final userMessage = messages[1] as Map<String, dynamic>;

    expect(userMessage['role'], 'user');
    expect(userMessage['content'], 'What is the capital of France?');
  });

  test(
    'complete() extracts choices[0].message.content from the response',
    () async {
      final transport = _FakeHttpTransport()
        ..responseBody =
            '{"choices": [{"message": {"content": "Extracted text."}}]}';
      final client = HttpOpenAIClient(transport: transport);
      const openAiConfig = OpenAIConfig(
        apiKey: 'sk-test',
        baseUrl: 'https://api.openai.com/v1/chat/completions',
      );

      final result = await client.complete(request, modelConfig, openAiConfig);

      expect(result.text, 'Extracted text.');
    },
  );

  test('complete() returns the correct OpenAIResult.text', () async {
    final transport = _FakeHttpTransport();
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );

    final result = await client.complete(request, modelConfig, openAiConfig);

    expect(result.text, 'Paris.');
  });

  test('complete() throws OpenAIException for a 401 error response', () async {
    final transport = _FakeHttpTransport()
      ..responseBody =
          '{"error": {"message": "Incorrect API key provided.", '
          '"type": "invalid_request_error", "code": "invalid_api_key"}}';
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );

    expect(
      () => client.complete(request, modelConfig, openAiConfig),
      throwsA(
        isA<OpenAIException>().having(
          (e) => e.message,
          'message',
          contains('OpenAI API error: Incorrect API key provided.'),
        ),
      ),
    );
  });

  test('complete() throws OpenAIException for a 404 error response', () async {
    final transport = _FakeHttpTransport()
      ..responseBody =
          '{"error": {"message": "Unknown request URL.", '
          '"type": "invalid_request_error", "code": null}}';
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );

    expect(
      () => client.complete(request, modelConfig, openAiConfig),
      throwsA(
        isA<OpenAIException>().having(
          (e) => e.message,
          'message',
          contains('OpenAI API error: Unknown request URL.'),
        ),
      ),
    );
  });

  test('complete() throws OpenAIException for a 429 error response', () async {
    final transport = _FakeHttpTransport()
      ..responseBody =
          '{"error": {"message": "You exceeded your current quota, '
          'please check your plan and billing details.", '
          '"type": "insufficient_quota", "code": "insufficient_quota"}}';
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );

    expect(
      () => client.complete(request, modelConfig, openAiConfig),
      throwsA(
        isA<OpenAIException>().having(
          (e) => e.message,
          'message',
          contains(
            'OpenAI API error: You exceeded your current quota, '
            'please check your plan and billing details.',
          ),
        ),
      ),
    );
  });

  test('complete() throws OpenAIException for a 500 error response', () async {
    final transport = _FakeHttpTransport()
      ..responseBody =
          '{"error": {"message": "The server had an error while '
          'processing your request.", "type": "server_error", '
          '"code": null}}';
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );

    expect(
      () => client.complete(request, modelConfig, openAiConfig),
      throwsA(
        isA<OpenAIException>().having(
          (e) => e.message,
          'message',
          contains(
            'OpenAI API error: The server had an error while '
            'processing your request.',
          ),
        ),
      ),
    );
  });

  test('complete() still parses a successful response normally alongside '
      'error handling', () async {
    final transport = _FakeHttpTransport();
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );

    final result = await client.complete(request, modelConfig, openAiConfig);

    expect(result.text, 'Paris.');
  });

  test(
    'complete() still parses successfully for a real HTTP 200 status',
    () async {
      final transport = _FakeHttpTransport()..statusCode = 200;
      final client = HttpOpenAIClient(transport: transport);
      const openAiConfig = OpenAIConfig(
        apiKey: 'sk-test',
        baseUrl: 'https://api.openai.com/v1/chat/completions',
      );

      final result = await client.complete(request, modelConfig, openAiConfig);

      expect(result.text, 'Paris.');
    },
  );

  test('complete() throws OpenAIException with the server message for an '
      'HTTP 400 status', () async {
    final transport = _FakeHttpTransport()
      ..statusCode = 400
      ..responseBody =
          '{"error": {"message": "Invalid request payload.", '
          '"type": "invalid_request_error", "code": null}}';
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );

    expect(
      () => client.complete(request, modelConfig, openAiConfig),
      throwsA(
        isA<OpenAIException>().having(
          (e) => e.message,
          'message',
          'Invalid request payload.',
        ),
      ),
    );
  });

  test('complete() throws OpenAIException with the server message for an '
      'HTTP 401 status', () async {
    final transport = _FakeHttpTransport()
      ..statusCode = 401
      ..responseBody =
          '{"error": {"message": "Incorrect API key provided.", '
          '"type": "invalid_request_error", "code": "invalid_api_key"}}';
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );

    expect(
      () => client.complete(request, modelConfig, openAiConfig),
      throwsA(
        isA<OpenAIException>().having(
          (e) => e.message,
          'message',
          'Incorrect API key provided.',
        ),
      ),
    );
  });

  test('complete() throws OpenAIException with the server message for an '
      'HTTP 404 status', () async {
    final transport = _FakeHttpTransport()
      ..statusCode = 404
      ..responseBody =
          '{"error": {"message": "Unknown request URL.", '
          '"type": "invalid_request_error", "code": null}}';
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );

    expect(
      () => client.complete(request, modelConfig, openAiConfig),
      throwsA(
        isA<OpenAIException>().having(
          (e) => e.message,
          'message',
          'Unknown request URL.',
        ),
      ),
    );
  });

  test('complete() throws OpenAIException with the server message for an '
      'HTTP 429 status', () async {
    final transport = _FakeHttpTransport()
      ..statusCode = 429
      ..responseBody =
          '{"error": {"message": "You exceeded your current quota, '
          'please check your plan and billing details.", '
          '"type": "insufficient_quota", "code": "insufficient_quota"}}';
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );

    expect(
      () => client.complete(request, modelConfig, openAiConfig),
      throwsA(
        isA<OpenAIException>().having(
          (e) => e.message,
          'message',
          'You exceeded your current quota, '
              'please check your plan and billing details.',
        ),
      ),
    );
  });

  test('complete() throws OpenAIException with the server message for an '
      'HTTP 500 status', () async {
    final transport = _FakeHttpTransport()
      ..statusCode = 500
      ..responseBody =
          '{"error": {"message": "The server had an error while '
          'processing your request.", "type": "server_error", '
          '"code": null}}';
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );

    expect(
      () => client.complete(request, modelConfig, openAiConfig),
      throwsA(
        isA<OpenAIException>().having(
          (e) => e.message,
          'message',
          'The server had an error while processing your request.',
        ),
      ),
    );
  });

  test('complete() throws OpenAIException(\'HTTP 503\') for an HTTP 503 '
      'status without an error object', () async {
    final transport = _FakeHttpTransport()
      ..statusCode = 503
      ..responseBody = 'Service Unavailable';
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );

    expect(
      () => client.complete(request, modelConfig, openAiConfig),
      throwsA(
        isA<OpenAIException>().having((e) => e.message, 'message', 'HTTP 503'),
      ),
    );
  });

  test('complete() omits the tools key when request.tools is empty', () async {
    final transport = _FakeHttpTransport();
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );

    await client.complete(request, modelConfig, openAiConfig);

    final decoded = jsonDecode(transport.capturedBody!) as Map<String, dynamic>;
    expect(decoded.containsKey('tools'), isFalse);
  });

  test('complete() serializes a single tool correctly', () async {
    final transport = _FakeHttpTransport();
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );
    const requestWithTools = ModelRequest(
      conversation: Conversation(
        messages: [
          SystemMessage(content: 'You are a helpful assistant.'),
          UserMessage(content: 'What is the capital of France?'),
        ],
      ),
      tools: [ToolDefinition(id: 'search', description: 'Search the web.')],
    );

    await client.complete(requestWithTools, modelConfig, openAiConfig);

    final decoded = jsonDecode(transport.capturedBody!) as Map<String, dynamic>;
    expect(decoded['tools'], [
      {
        'type': 'function',
        'function': {'name': 'search', 'description': 'Search the web.'},
      },
    ]);
  });

  test(
    'complete() serializes multiple tools correctly, preserving order',
    () async {
      final transport = _FakeHttpTransport();
      final client = HttpOpenAIClient(transport: transport);
      const openAiConfig = OpenAIConfig(
        apiKey: 'sk-test',
        baseUrl: 'https://api.openai.com/v1/chat/completions',
      );
      const requestWithTools = ModelRequest(
        conversation: Conversation(
          messages: [
            SystemMessage(content: 'You are a helpful assistant.'),
            UserMessage(content: 'What is the capital of France?'),
          ],
        ),
        tools: [
          ToolDefinition(id: 'search', description: 'Search the web.'),
          ToolDefinition(id: 'calculator', description: 'Evaluate math.'),
        ],
      );

      await client.complete(requestWithTools, modelConfig, openAiConfig);

      final decoded =
          jsonDecode(transport.capturedBody!) as Map<String, dynamic>;
      expect(decoded['tools'], [
        {
          'type': 'function',
          'function': {'name': 'search', 'description': 'Search the web.'},
        },
        {
          'type': 'function',
          'function': {'name': 'calculator', 'description': 'Evaluate math.'},
        },
      ]);
    },
  );

  test('complete() still encodes model, temperature, and messages unchanged '
      'when tools are present', () async {
    final transport = _FakeHttpTransport();
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );
    const requestWithTools = ModelRequest(
      conversation: Conversation(
        messages: [
          SystemMessage(content: 'You are a helpful assistant.'),
          UserMessage(content: 'What is the capital of France?'),
        ],
      ),
      tools: [ToolDefinition(id: 'search', description: 'Search the web.')],
    );

    await client.complete(requestWithTools, modelConfig, openAiConfig);

    final decoded = jsonDecode(transport.capturedBody!) as Map<String, dynamic>;
    expect(decoded['model'], 'gpt-4');
    expect(decoded['temperature'], 0.7);

    final messages = decoded['messages'] as List<dynamic>;
    expect(
      (messages[0] as Map<String, dynamic>)['content'],
      'You are a helpful assistant.',
    );
    expect(
      (messages[1] as Map<String, dynamic>)['content'],
      'What is the capital of France?',
    );
  });

  test('complete() returns an empty toolCalls list when tool_calls is '
      'absent', () async {
    final transport = _FakeHttpTransport();
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );

    final result = await client.complete(request, modelConfig, openAiConfig);

    expect(result.toolCalls, isEmpty);
  });

  test('complete() returns an empty toolCalls list when tool_calls is an '
      'empty array', () async {
    final transport = _FakeHttpTransport()
      ..responseBody =
          '{"choices": [{"message": {"content": "Paris.", '
          '"tool_calls": []}}]}';
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );

    final result = await client.complete(request, modelConfig, openAiConfig);

    expect(result.toolCalls, isEmpty);
  });

  test('complete() parses a single tool call correctly', () async {
    final transport = _FakeHttpTransport()
      ..responseBody =
          '{"choices": [{"message": {"content": "", "tool_calls": ['
          '{"id": "call_123", "type": "function", "function": '
          '{"name": "search", "arguments": "{\\"query\\":\\"Paris\\"}"}}'
          ']}}]}';
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );

    final result = await client.complete(request, modelConfig, openAiConfig);

    expect(result.toolCalls, hasLength(1));
    expect(result.toolCalls.first.id, 'call_123');
    expect(result.toolCalls.first.name, 'search');
    expect(result.toolCalls.first.arguments, '{"query":"Paris"}');
  });

  test(
    'complete() parses multiple tool calls correctly, preserving order',
    () async {
      final transport = _FakeHttpTransport()
        ..responseBody =
            '{"choices": [{"message": {"content": "", "tool_calls": ['
            '{"id": "call_1", "type": "function", "function": '
            '{"name": "search", "arguments": "{}"}},'
            '{"id": "call_2", "type": "function", "function": '
            '{"name": "calculator", "arguments": "{}"}}'
            ']}}]}';
      final client = HttpOpenAIClient(transport: transport);
      const openAiConfig = OpenAIConfig(
        apiKey: 'sk-test',
        baseUrl: 'https://api.openai.com/v1/chat/completions',
      );

      final result = await client.complete(request, modelConfig, openAiConfig);

      expect(result.toolCalls, hasLength(2));
      expect(result.toolCalls[0].id, 'call_1');
      expect(result.toolCalls[0].name, 'search');
      expect(result.toolCalls[1].id, 'call_2');
      expect(result.toolCalls[1].name, 'calculator');
    },
  );

  test(
    'complete() preserves assistant text when tool calls are present',
    () async {
      final transport = _FakeHttpTransport()
        ..responseBody =
            '{"choices": [{"message": {"content": "Here is the answer.", '
            '"tool_calls": [{"id": "call_1", "type": "function", '
            '"function": {"name": "search", "arguments": "{}"}}]}}]}';
      final client = HttpOpenAIClient(transport: transport);
      const openAiConfig = OpenAIConfig(
        apiKey: 'sk-test',
        baseUrl: 'https://api.openai.com/v1/chat/completions',
      );

      final result = await client.complete(request, modelConfig, openAiConfig);

      expect(result.text, 'Here is the answer.');
      expect(result.toolCalls, hasLength(1));
    },
  );

  test('complete() returns an empty text when content is null and a tool '
      'call is present', () async {
    final transport = _FakeHttpTransport()
      ..responseBody =
          '{"choices": [{"message": {"content": null, "tool_calls": '
          '[{"id": "call_1", "type": "function", "function": '
          '{"name": "search", "arguments": "{}"}}]}}]}';
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );

    final result = await client.complete(request, modelConfig, openAiConfig);

    expect(result.text, '');
  });

  test('complete() still parses the tool call when content is null', () async {
    final transport = _FakeHttpTransport()
      ..responseBody =
          '{"choices": [{"message": {"content": null, "tool_calls": '
          '[{"id": "call_1", "type": "function", "function": '
          '{"name": "search", "arguments": "{\\"query\\":\\"Paris\\"}"}}]}}]}';
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );

    final result = await client.complete(request, modelConfig, openAiConfig);

    expect(result.toolCalls, hasLength(1));
    expect(result.toolCalls.first.id, 'call_1');
    expect(result.toolCalls.first.name, 'search');
    expect(result.toolCalls.first.arguments, '{"query":"Paris"}');
  });

  test('complete() leaves normal string content unchanged', () async {
    final transport = _FakeHttpTransport()
      ..responseBody = '{"choices": [{"message": {"content": "Paris."}}]}';
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );

    final result = await client.complete(request, modelConfig, openAiConfig);

    expect(result.text, 'Paris.');
  });

  test('complete() returns an empty text when content is missing entirely '
      'but a tool call is present', () async {
    final transport = _FakeHttpTransport()
      ..responseBody =
          '{"choices": [{"message": {"tool_calls": '
          '[{"id": "call_1", "type": "function", "function": '
          '{"name": "search", "arguments": "{}"}}]}}]}';
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );

    final result = await client.complete(request, modelConfig, openAiConfig);

    expect(result.text, '');
    expect(result.toolCalls, hasLength(1));
  });

  test('complete() produces an identical messages payload when '
      'request.toolOutputs is empty', () async {
    final transport = _FakeHttpTransport();
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );

    await client.complete(request, modelConfig, openAiConfig);

    final decoded = jsonDecode(transport.capturedBody!) as Map<String, dynamic>;
    final messages = decoded['messages'] as List<dynamic>;

    expect(messages, hasLength(2));
    expect((messages[0] as Map<String, dynamic>)['role'], 'system');
    expect((messages[1] as Map<String, dynamic>)['role'], 'user');
  });

  test('complete() serializes a single ToolOutput as a tool message', () async {
    final transport = _FakeHttpTransport();
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );
    const requestWithToolOutputs = ModelRequest(
      conversation: Conversation(
        messages: [
          SystemMessage(content: 'You are a helpful assistant.'),
          UserMessage(content: 'What is the capital of France?'),
        ],
      ),
      toolOutputs: [
        ToolOutput(
          toolCallId: 'call_1',
          toolName: 'search',
          success: true,
          content: 'Paris is the capital of France.',
        ),
      ],
    );

    await client.complete(requestWithToolOutputs, modelConfig, openAiConfig);

    final decoded = jsonDecode(transport.capturedBody!) as Map<String, dynamic>;
    final messages = decoded['messages'] as List<dynamic>;

    expect(messages, hasLength(3));
    expect(messages[2], {
      'role': 'tool',
      'tool_call_id': 'call_1',
      'content': 'Paris is the capital of France.',
    });
  });

  test('complete() serializes multiple ToolOutputs as tool messages, '
      'preserving order', () async {
    final transport = _FakeHttpTransport();
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );
    const requestWithToolOutputs = ModelRequest(
      conversation: Conversation(
        messages: [
          SystemMessage(content: 'You are a helpful assistant.'),
          UserMessage(content: 'What is the capital of France?'),
        ],
      ),
      toolOutputs: [
        ToolOutput(
          toolCallId: 'call_1',
          toolName: 'search',
          success: true,
          content: 'first output',
        ),
        ToolOutput(
          toolCallId: 'call_2',
          toolName: 'calculator',
          success: false,
          content: 'second output',
        ),
      ],
    );

    await client.complete(requestWithToolOutputs, modelConfig, openAiConfig);

    final decoded = jsonDecode(transport.capturedBody!) as Map<String, dynamic>;
    final messages = decoded['messages'] as List<dynamic>;

    expect(messages, hasLength(4));
    expect(messages[2], {
      'role': 'tool',
      'tool_call_id': 'call_1',
      'content': 'first output',
    });
    expect(messages[3], {
      'role': 'tool',
      'tool_call_id': 'call_2',
      'content': 'second output',
    });
  });

  test('complete() does not touch the system message, user message, or '
      'tool definitions when toolOutputs are present', () async {
    final transport = _FakeHttpTransport();
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );
    const requestWithBoth = ModelRequest(
      conversation: Conversation(
        messages: [
          SystemMessage(content: 'You are a helpful assistant.'),
          UserMessage(content: 'What is the capital of France?'),
        ],
      ),
      tools: [ToolDefinition(id: 'search', description: 'Search the web.')],
      toolOutputs: [
        ToolOutput(
          toolCallId: 'call_1',
          toolName: 'search',
          success: true,
          content: 'Paris.',
        ),
      ],
    );

    await client.complete(requestWithBoth, modelConfig, openAiConfig);

    final decoded = jsonDecode(transport.capturedBody!) as Map<String, dynamic>;
    final messages = decoded['messages'] as List<dynamic>;

    expect(
      (messages[0] as Map<String, dynamic>)['content'],
      'You are a helpful assistant.',
    );
    expect(
      (messages[1] as Map<String, dynamic>)['content'],
      'What is the capital of France?',
    );
    expect(decoded['tools'], [
      {
        'type': 'function',
        'function': {'name': 'search', 'description': 'Search the web.'},
      },
    ]);
  });

  test('complete() serializes a SystemMessage correctly', () async {
    final transport = _FakeHttpTransport();
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );
    const requestWithSystemOnly = ModelRequest(
      conversation: Conversation(
        messages: [SystemMessage(content: 'You are a helpful assistant.')],
      ),
    );

    await client.complete(requestWithSystemOnly, modelConfig, openAiConfig);

    final decoded = jsonDecode(transport.capturedBody!) as Map<String, dynamic>;
    final messages = decoded['messages'] as List<dynamic>;

    expect(messages, [
      {'role': 'system', 'content': 'You are a helpful assistant.'},
    ]);
  });

  test('complete() serializes a UserMessage correctly', () async {
    final transport = _FakeHttpTransport();
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );
    const requestWithUserOnly = ModelRequest(
      conversation: Conversation(
        messages: [UserMessage(content: 'What is the capital of France?')],
      ),
    );

    await client.complete(requestWithUserOnly, modelConfig, openAiConfig);

    final decoded = jsonDecode(transport.capturedBody!) as Map<String, dynamic>;
    final messages = decoded['messages'] as List<dynamic>;

    expect(messages, [
      {'role': 'user', 'content': 'What is the capital of France?'},
    ]);
  });

  test(
    'complete() serializes an AssistantMessage without tool calls correctly',
    () async {
      final transport = _FakeHttpTransport();
      final client = HttpOpenAIClient(transport: transport);
      const openAiConfig = OpenAIConfig(
        apiKey: 'sk-test',
        baseUrl: 'https://api.openai.com/v1/chat/completions',
      );
      const requestWithAssistant = ModelRequest(
        conversation: Conversation(
          messages: [
            AssistantMessage(content: 'Paris is the capital of France.'),
          ],
        ),
      );

      await client.complete(requestWithAssistant, modelConfig, openAiConfig);

      final decoded =
          jsonDecode(transport.capturedBody!) as Map<String, dynamic>;
      final messages = decoded['messages'] as List<dynamic>;

      expect(messages, [
        {'role': 'assistant', 'content': 'Paris is the capital of France.'},
      ]);
    },
  );

  test(
    'complete() serializes an AssistantMessage with tool calls correctly',
    () async {
      final transport = _FakeHttpTransport();
      final client = HttpOpenAIClient(transport: transport);
      const openAiConfig = OpenAIConfig(
        apiKey: 'sk-test',
        baseUrl: 'https://api.openai.com/v1/chat/completions',
      );
      const requestWithAssistant = ModelRequest(
        conversation: Conversation(
          messages: [
            AssistantMessage(
              content: '',
              toolCalls: [
                ToolCall(
                  id: 'call_1',
                  name: 'search',
                  arguments: '{"query":"Paris"}',
                ),
              ],
            ),
          ],
        ),
      );

      await client.complete(requestWithAssistant, modelConfig, openAiConfig);

      final decoded =
          jsonDecode(transport.capturedBody!) as Map<String, dynamic>;
      final messages = decoded['messages'] as List<dynamic>;

      expect(messages, [
        {
          'role': 'assistant',
          'content': '',
          'tool_calls': [
            {
              'id': 'call_1',
              'type': 'function',
              'function': {'name': 'search', 'arguments': '{"query":"Paris"}'},
            },
          ],
        },
      ]);
    },
  );

  test('complete() serializes a ToolMessage correctly', () async {
    final transport = _FakeHttpTransport();
    final client = HttpOpenAIClient(transport: transport);
    const openAiConfig = OpenAIConfig(
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1/chat/completions',
    );
    const requestWithToolMessage = ModelRequest(
      conversation: Conversation(
        messages: [
          ToolMessage(
            toolCallId: 'call_1',
            toolName: 'search',
            content: 'Paris is the capital of France.',
          ),
        ],
      ),
    );

    await client.complete(requestWithToolMessage, modelConfig, openAiConfig);

    final decoded = jsonDecode(transport.capturedBody!) as Map<String, dynamic>;
    final messages = decoded['messages'] as List<dynamic>;

    expect(messages, [
      {
        'role': 'tool',
        'tool_call_id': 'call_1',
        'content': 'Paris is the capital of France.',
      },
    ]);
  });

  test(
    'complete() preserves order across mixed Conversation message types',
    () async {
      final transport = _FakeHttpTransport();
      final client = HttpOpenAIClient(transport: transport);
      const openAiConfig = OpenAIConfig(
        apiKey: 'sk-test',
        baseUrl: 'https://api.openai.com/v1/chat/completions',
      );
      const requestWithMixedConversation = ModelRequest(
        conversation: Conversation(
          messages: [
            SystemMessage(content: 'You are a helpful assistant.'),
            UserMessage(content: 'What is the capital of France?'),
            AssistantMessage(
              content: '',
              toolCalls: [
                ToolCall(
                  id: 'call_1',
                  name: 'search',
                  arguments: '{"query":"Paris"}',
                ),
              ],
            ),
            ToolMessage(
              toolCallId: 'call_1',
              toolName: 'search',
              content: 'Paris is the capital of France.',
            ),
            AssistantMessage(content: 'Paris is the capital of France.'),
          ],
        ),
      );

      await client.complete(
        requestWithMixedConversation,
        modelConfig,
        openAiConfig,
      );

      final decoded =
          jsonDecode(transport.capturedBody!) as Map<String, dynamic>;
      final messages = decoded['messages'] as List<dynamic>;

      expect(
        messages.map((m) => (m as Map<String, dynamic>)['role']).toList(),
        ['system', 'user', 'assistant', 'tool', 'assistant'],
      );
    },
  );
}
