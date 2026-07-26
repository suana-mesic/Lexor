import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:lexor_mobile/config/api_config.dart';
import 'package:lexor_shared/lexor_shared.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lexor_mobile/providers/auth_provider.dart';

const _tokenKey = 'access_token';
const _refreshTokenKey = 'refresh_token';
const _storage = FlutterSecureStorage();

/// Persists the access token so the session survives app restarts.
Future<void> saveToken(String token) =>
    _storage.write(key: _tokenKey, value: token);

/// Persists the refresh token so logout can revoke it on the server
/// even after an app restart.
Future<void> saveRefreshToken(String token) =>
    _storage.write(key: _refreshTokenKey, value: token);

/// Removes the stored token (on logout / session expiry).
Future<void> clearToken() async {
  await _storage.delete(key: _tokenKey);
  await _storage.delete(key: _refreshTokenKey);
}

/// On startup, restores a stored, non-expired token into [AuthProvider].
/// Returns true if a valid session was restored, false otherwise.
Future<bool> loadToken() async {
  final token = await _storage.read(key: _tokenKey);
  final refresh = await _storage.read(key: _refreshTokenKey);

  if (token != null && !JwtDecoder.isExpired(token)) {
    AuthProvider.accessToken = token;
    AuthProvider.refreshToken = refresh;
    return true;
  }

  if (refresh != null && refresh.isNotEmpty) {
    final result = await AuthService.refresh(ApiConfig.baseUrl, refresh);
    if (result != null) {
      AuthProvider.accessToken = result.accessToken;
      AuthProvider.refreshToken = result.refreshToken;
      await saveToken(result.accessToken);
      await saveRefreshToken(result.refreshToken);
      return true;
    }
  }

  await _storage.delete(key: _tokenKey);
  await _storage.delete(key: _refreshTokenKey);
  return false;
}
