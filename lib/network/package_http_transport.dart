import 'package:http/http.dart' as http;
import 'package:pharos_ai_runtime/network/http_transport.dart';

class PackageHttpTransport extends HttpTransport {
  PackageHttpTransport({required http.Client client}) : _client = client;

  final http.Client _client;

  @override
  Future<String> post({
    required Uri uri,
    required Map<String, String> headers,
    required String body,
  }) async {
    final response = await _client.post(uri, headers: headers, body: body);

    return response.body;
  }
}
