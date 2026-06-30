import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lexor_mobile/providers/auth_provider.dart';

const _tokenKey = 'access_token';

/// Persists the access token so the session survives app restarts.
Future<void> saveToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_tokenKey, token);
}

/// Removes the stored token (on logout / session expiry).
Future<void> clearToken() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_tokenKey);
}

/// On startup, restores a stored, non-expired token into [AuthProvider].
/// Returns true if a valid session was restored, false otherwise.
Future<bool> loadToken() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString(_tokenKey);
  if (token != null && !JwtDecoder.isExpired(token)) {
    AuthProvider.accessToken = token;
    return true;
  }
  if (token != null) await prefs.remove(_tokenKey);
  return false;
}
