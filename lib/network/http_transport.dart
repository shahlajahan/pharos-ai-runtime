import 'package:pharos_ai_runtime/network/http_transport_response.dart';

abstract class HttpTransport {
  Future<HttpTransportResponse> post({
    required Uri uri,
    required Map<String, String> headers,
    required String body,
  });
}
