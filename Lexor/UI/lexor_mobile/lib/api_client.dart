import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lexor_mobile/auth_store.dart';
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
    Future<http.Response> Function() request, {
    bool isRetry = false,
  }) async {
    http.Response res;
    try {
      res = await request();
    } catch (e) {
      throw ApiException(ApiError.fromException(e));
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.body.isEmpty ? null : jsonDecode(res.body);
    }
    if (res.statusCode == 401 && !isRetry) {
      // Access token expired → try to refresh once, then replay the request.
      if (await _tryRefresh()) {
        return _send(request, isRetry: true);
      }
      handleSessionExpired();
    }
    throw ApiException(ApiError.fromResponse(res));
  }

  static Future<bool> _tryRefresh() async {
    final refresh = AuthProvider.refreshToken;
    if (refresh == null || refresh.isEmpty) return false;
    final result = await AuthService.refresh(ApiConfig.baseUrl, refresh);
    if (result == null) return false;
    AuthProvider.accessToken = result.accessToken;
    AuthProvider.refreshToken = result.refreshToken;
    await saveToken(result.accessToken);
    await saveRefreshToken(result.refreshToken);
    return true;
  }
}
