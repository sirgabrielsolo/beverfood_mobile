import 'dart:convert';

import 'package:http/http.dart' as http;

/// JSON client for the Beverfood web app's API (`/api/v1`), which serves the
/// same product database the agents use. Everything but signing in needs the
/// client's [token] (see `AuthController`).
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

  /// Sent as `Authorization: Bearer …` when set.
  String? token;

  /// Called when the server refuses [token] (expired, signed out elsewhere,
  /// account deleted): the app then signs out.
  void Function()? onUnauthorized;

  Future<Object?> getJson(String path) => _send('GET', path);

  Future<Object?> postJson(String path, [Map<String, Object?>? body]) =>
      _send('POST', path, body);

  Future<Object?> putJson(String path, Map<String, Object?> body) =>
      _send('PUT', path, body);

  Future<Object?> delete(String path) => _send('DELETE', path);

  /// Sends a request and decodes the JSON answer (null when empty). Throws
  /// [ApiException] with the server's Italian message on an error answer,
  /// or a generic one when the server can't be reached.
  Future<Object?> _send(
    String method,
    String path, [
    Map<String, Object?>? body,
  ]) async {
    final sentToken = token;
    final request = http.Request(method, Uri.parse('$baseUrl$path'));
    if (sentToken != null) {
      request.headers['Authorization'] = 'Bearer $sentToken';
    }
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(_timeout),
      ).timeout(_timeout);
    } on Exception {
      throw const ApiException.offline();
    }

    // Decoded as UTF-8 whatever the headers say: names carry accents.
    final text = utf8.decode(response.bodyBytes);
    Object? json;
    try {
      json = text.isEmpty ? null : jsonDecode(text);
    } on FormatException {
      json = null;
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return json;

    if (response.statusCode == 401 && sentToken != null) onUnauthorized?.call();
    final map = json is Map<String, Object?> ? json : const <String, Object?>{};
    throw ApiException(
      map['error'] as String? ?? 'Qualcosa non ha funzionato. Riprova.',
      code: map['code'] as String? ?? 'http_${response.statusCode}',
      status: response.statusCode,
      field: map['field'] as String?,
      details: map,
    );
  }
}

/// An error to show the client: [message] is Italian, ready for the screen.
class ApiException implements Exception {
  const ApiException(
    this.message, {
    required this.code,
    this.status,
    this.field,
    this.details = const {},
  });

  const ApiException.offline()
    : message = 'Connessione non riuscita. Controlla la rete e riprova.',
      code = 'offline',
      status = null,
      field = null,
      details = const {};

  final String message;

  /// The server's machine-readable code, e.g. `wrong_code`, `too_soon`.
  final String code;
  final int? status;

  /// The request field the error is about, e.g. `phone`, `vat_number`.
  final String? field;

  /// The whole error body, e.g. `retry_after` or `attempts_left`.
  final Map<String, Object?> details;

  bool get isOffline => code == 'offline';

  @override
  String toString() => 'ApiException($code): $message';
}
