import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

import 'api_error.dart';
import 'api_exception.dart';

/// Result of a successful login.
class AuthResult {
  final String accessToken;
  final int? userId;
  final String refreshToken;
  AuthResult(this.accessToken, this.userId, this.refreshToken);
}

/// Shared authentication core used by both apps: the `Access/login`/`Access/logout`
/// calls and the JWT claim parsing live here once, so the endpoints and claim
/// names can't drift between apps.
class AuthService {
  final String baseUrl;
  AuthService(this.baseUrl);

  Future<AuthResult> login(String username, String password) async {
    final uri = Uri.parse('$baseUrl/Access/login');
    http.Response response;
    try {
      response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
    } catch (e) {
      throw ApiException(ApiError.fromException(e));
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return AuthResult(
        data['accessToken'] as String,
        data['userId'] as int?,
        data['refreshToken'] as String? ?? '',
      );
    }
    if (response.statusCode == 401) {
      throw ApiException('Neispravno korisničko ime ili lozinka.');
    }
    throw ApiException(ApiError.fromResponse(response));
  }

  /// Server-side logout: revokes the refresh token so it can't be reused.
  /// Best-effort — the caller still clears its local token even if this fails.
  static Future<void> logout(
    String baseUrl,
    String accessToken,
    String refreshToken,
  ) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/Access/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'refreshToken': refreshToken}),
      );
    } catch (_) {
      // Ignore — local logout proceeds regardless of a failed server call.
    }
  }

  static Future<AuthResult?> refresh(
    String baseUrl,
    String refreshToken,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Access/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AuthResult(
          data['accessToken'],
          data['userId'],
          data['refreshToken'],
        );
      }
    } catch (_) {
      // Network/parse error → treat as failed refresh.
    }
    return null;
  }

  /// Roles from the JWT `role` claim (single value or list).
  static List<String> rolesFromToken(String token) {
    final role = JwtDecoder.decode(token)['role'];
    if (role is List) return role.map((e) => e.toString()).toList();
    if (role is String) return [role];
    return const [];
  }

  /// "First Last" from the JWT `given_name` / `family_name` claims.
  static String fullNameFromToken(String token) {
    final decoded = JwtDecoder.decode(token);
    return '${decoded['given_name'] ?? ''} ${decoded['family_name'] ?? ''}'
        .trim();
  }
}
