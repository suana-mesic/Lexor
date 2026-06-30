import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lexor_mobile/config/api_config.dart';
import 'package:lexor_mobile/providers/auth_provider.dart';
import 'package:lexor_mobile/session.dart';
import 'package:lexor_shared/lexor_shared.dart';

/// Single HTTP entry point for the mobile app: attaches auth headers, maps
/// connection/HTTP failures to [ApiException], and redirects to login on 401.
/// Returns the decoded JSON body on success (2xx), or null for an empty body.
class ApiClient {
  static Future<dynamic> get(String path, {Map<String, String>? query}) {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}$path',
    ).replace(queryParameters: query);
    return _send(() => http.get(uri, headers: _headers()));
  }

  static Future<dynamic> post(String path, {Object? body}) {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    return _send(
      () => http.post(uri, headers: _headers(), body: jsonEncode(body)),
    );
  }

  static Future<dynamic> put(String path, {Object? body}) {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    return _send(
      () => http.put(uri, headers: _headers(), body: jsonEncode(body)),
    );
  }

  static Map<String, String> _headers() => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${AuthProvider.accessToken}',
  };

  static Future<dynamic> _send(
    Future<http.Response> Function() request,
  ) async {
    http.Response res;
    try {
      res = await request();
    } catch (e) {
      throw ApiException(ApiError.fromException(e));
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.body.isEmpty ? null : jsonDecode(res.body);
    }
    if (ApiError.isSessionExpired(res)) handleSessionExpired();
    throw ApiException(ApiError.fromResponse(res));
  }
}
