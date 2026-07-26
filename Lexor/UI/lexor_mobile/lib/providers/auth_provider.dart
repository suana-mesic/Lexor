import 'package:flutter/foundation.dart';
import 'package:lexor_mobile/config/api_config.dart';
import 'package:lexor_mobile/auth_store.dart';
import 'package:lexor_mobile/session.dart';
import 'package:lexor_shared/lexor_shared.dart';

class AuthProvider extends ChangeNotifier {
  static String? accessToken;
  static String? refreshToken;
  int? userId;

  Future<void> login(String username, String password) async {
    final result = await AuthService(
      ApiConfig.baseUrl,
    ).login(username, password);
    accessToken = result.accessToken;
    refreshToken = result.refreshToken;
    userId = result.userId;
    await saveToken(result.accessToken);
    await saveRefreshToken(result.refreshToken);
    resetSessionExpiredGuard();
    notifyListeners();
  }

  String get fullName =>
      accessToken == null ? '' : AuthService.fullNameFromToken(accessToken!);

  Future<void> logout() async {
    final token = accessToken;
    final refresh = refreshToken;

    if (token != null && refresh != null && refresh.isNotEmpty) {
      await AuthService.logout(ApiConfig.baseUrl, token, refresh);
    }
    accessToken = null;
    refreshToken = null;
    userId = null;
    await clearToken();
    notifyListeners();
  }
}
