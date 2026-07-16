import 'package:pharos_ai_runtime/network/http_transport.dart';
import 'package:pharos_ai_runtime/network/http_transport_response.dart';
import 'package:test/test.dart';

class _FakeHttpTransport extends HttpTransport {
  Uri? capturedUri;
  Map<String, String>? capturedHeaders;
  String? capturedBody;

  @override
  Future<HttpTransportResponse> post({
    required Uri uri,
    required Map<String, String> headers,
    required String body,
  }) async {
    capturedUri = uri;
    capturedHeaders = headers;
    capturedBody = body;

    return const HttpTransportResponse(
      statusCode: 200,
      headers: {},
      body: 'fake response body',
    );
  }
}

void main() {
  test('post() passes uri through unchanged', () async {
    final transport = _FakeHttpTransport();
    final uri = Uri.parse('https://api.example.com/v1/chat');

    await transport.post(uri: uri, headers: const {}, body: '{}');

    expect(transport.capturedUri, same(uri));
  });

  test('post() passes headers through unchanged', () async {
    final transport = _FakeHttpTransport();
    final headers = {'Content-Type': 'application/json'};

    await transport.post(
      uri: Uri.parse('https://api.example.com/v1/chat'),
      headers: headers,
      body: '{}',
    );

    expect(transport.capturedHeaders, same(headers));
  });

  test('post() passes body through unchanged', () async {
    final transport = _FakeHttpTransport();
    const body = '{"prompt": "hello"}';

    await transport.post(
      uri: Uri.parse('https://api.example.com/v1/chat'),
      headers: const {},
      body: body,
    );

    expect(transport.capturedBody, same(body));
  });

  test('post() returns the raw response body unchanged', () async {
    final transport = _FakeHttpTransport();

    final response = await transport.post(
      uri: Uri.parse('https://api.example.com/v1/chat'),
      headers: const {},
      body: '{}',
    );

    expect(response.body, 'fake response body');
  });
}
