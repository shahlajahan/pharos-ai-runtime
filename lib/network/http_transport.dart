abstract class HttpTransport {
  Future<String> post({
    required Uri uri,
    required Map<String, String> headers,
    required String body,
  });
}
