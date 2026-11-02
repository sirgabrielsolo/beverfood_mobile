import 'dart:convert';

import 'package:http/http.dart' as http;

/// JSON client for the Beverfood web app's read-only API (`/api/v1`), which
/// serves the same product database the agents use.
///
/// The server defaults to production. To use a local server, run with e.g.
/// `--dart-define=API_BASE_URL=http://10.0.2.2:5000` (the Android emulator's
/// address for the host machine; debug builds allow plain HTTP).
class ApiClient {
  ApiClient({http.Client? client, this.baseUrl = defaultBaseUrl})
    : _client = client ?? http.Client();

  static const defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://beverfood-web.onrender.com',
  );

  static const _timeout = Duration(seconds: 15);

  final String baseUrl;
  final http.Client _client;

  /// GETs [path] (e.g. `/api/v1/promos`) and decodes the JSON body.
  /// Throws [ApiException] on a non-200 answer or a timeout.
  Future<Object?> getJson(String path) async {
    final http.Response response;
    try {
      response = await _client
          .get(Uri.parse('$baseUrl$path'))
          .timeout(_timeout);
    } on Exception catch (error) {
      throw ApiException('GET $path failed: $error');
    }
    if (response.statusCode != 200) {
      throw ApiException('GET $path answered ${response.statusCode}');
    }
    // Decoded as UTF-8 whatever the headers say: names carry accents.
    return jsonDecode(utf8.decode(response.bodyBytes));
  }
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => 'ApiException: $message';
}
