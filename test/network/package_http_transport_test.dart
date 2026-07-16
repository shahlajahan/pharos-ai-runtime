import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pharos_ai_runtime/network/package_http_transport.dart';
import 'package:test/test.dart';

class _FakeHttpClient extends http.BaseClient {
  http.BaseRequest? capturedRequest;
  String? capturedBody;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    capturedRequest = request;

    if (request is http.Request) {
      capturedBody = request.body;
    }

    return http.StreamedResponse(
      Stream.value(utf8.encode('fake response body')),
      200,
      request: request,
    );
  }
}

void main() {
  test('post() calls POST on the injected client', () async {
    final client = _FakeHttpClient();
    final transport = PackageHttpTransport(client: client);

    await transport.post(
      uri: Uri.parse('https://api.example.com/v1/chat'),
      headers: const {'Content-Type': 'application/json'},
      body: '{}',
    );

    expect(client.capturedRequest, isNotNull);
    expect(client.capturedRequest!.method, 'POST');
  });

  test('post() forwards the uri unchanged', () async {
    final client = _FakeHttpClient();
    final transport = PackageHttpTransport(client: client);
    final uri = Uri.parse('https://api.example.com/v1/chat');

    await transport.post(uri: uri, headers: const {}, body: '{}');

    expect(client.capturedRequest!.url, uri);
  });

  test('post() forwards the headers unchanged', () async {
    final client = _FakeHttpClient();
    final transport = PackageHttpTransport(client: client);
    final headers = {'Content-Type': 'application/json', 'X-Test': 'value'};

    await transport.post(
      uri: Uri.parse('https://api.example.com/v1/chat'),
      headers: headers,
      body: '{}',
    );

    for (final entry in headers.entries) {
      expect(client.capturedRequest!.headers[entry.key], entry.value);
    }
  });

  test('post() forwards the body unchanged', () async {
    final client = _FakeHttpClient();
    final transport = PackageHttpTransport(client: client);
    const body = '{"prompt": "hello"}';

    await transport.post(
      uri: Uri.parse('https://api.example.com/v1/chat'),
      headers: const {},
      body: body,
    );

    expect(client.capturedBody, body);
  });

  test('post() returns response.body unchanged', () async {
    final client = _FakeHttpClient();
    final transport = PackageHttpTransport(client: client);

    final result = await transport.post(
      uri: Uri.parse('https://api.example.com/v1/chat'),
      headers: const {},
      body: '{}',
    );

    expect(result, 'fake response body');
  });
}
