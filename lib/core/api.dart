import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_state.dart';
import 'config.dart';

class ApiException implements Exception {
  ApiException(this.status, this.code, [this.body]);

  /// HTTP status, or 0 when the server could not be reached.
  final int status;
  final String code;
  final Map<String, dynamic>? body;

  @override
  String toString() => 'ApiException($status, $code)';
}

/// Talks to the website's Express backend. The admin session is the same
/// `aa_admin` cookie the website uses; the app keeps it and sends it back.
class ApiClient {
  ApiClient(this._state);

  final AppState _state;
  final http.Client _http = http.Client();

  Future<dynamic> get(String path) => _send('GET', path);
  Future<dynamic> post(String path, [Object? body]) => _send('POST', path, body ?? const <String, dynamic>{});
  Future<dynamic> patch(String path, Object body) => _send('PATCH', path, body);
  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(String method, String path, [Object? body]) async {
    final uri = Uri.parse('${AppConfig.apiBase}$path');
    final request = http.Request(method, uri);
    request.headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }
    final token = _state.adminToken;
    if (token != null && token.isNotEmpty) {
      request.headers['Cookie'] = 'aa_admin=$token';
    }

    http.Response res;
    try {
      final streamed = await _http.send(request).timeout(AppConfig.timeout);
      res = await http.Response.fromStream(streamed).timeout(AppConfig.timeout);
    } on TimeoutException {
      throw ApiException(0, 'timeout');
    } catch (_) {
      throw ApiException(0, 'network');
    }

    // Keep the admin session cookie (set on login, refreshed on password change, cleared on logout).
    final setCookie = res.headers['set-cookie'];
    if (setCookie != null && setCookie.contains('aa_admin=')) {
      final match = RegExp(r'aa_admin=([^;,]*)').firstMatch(setCookie);
      _state.storeToken(match?.group(1));
    }

    dynamic data;
    final contentType = res.headers['content-type'] ?? '';
    if (contentType.contains('application/json') && res.bodyBytes.isNotEmpty) {
      try {
        data = jsonDecode(utf8.decode(res.bodyBytes));
      } catch (_) {
        data = null;
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      // A 200 without JSON means the request never reached the API (e.g. a static page).
      if (data == null) throw ApiException(res.statusCode, 'bad_response');
      return data;
    }

    if (res.statusCode == 401 && (path.startsWith('/admin') || path == '/auth/me')) {
      _state.handleUnauthorized();
    }

    final map = data is Map ? Map<String, dynamic>.from(data) : null;
    final code = map != null && map['error'] is String ? map['error'] as String : 'http_${res.statusCode}';
    throw ApiException(res.statusCode, code, map);
  }
}
