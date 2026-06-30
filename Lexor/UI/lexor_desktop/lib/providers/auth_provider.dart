import 'package:flutter/material.dart';
import 'package:lexor_desktop/config/api_config.dart';
import 'package:lexor_shared/lexor_shared.dart';

class AuthProvider extends ChangeNotifier {
  static String? accessToken;
  static String? refreshToken;
  int? userId;

  Future<void> login(String username, String password) async {
    final result = await AuthService(ApiConfig.baseUrl).login(username, password);

    final isAdmin =
        AuthService.rolesFromToken(result.accessToken).contains('Administrator');
    if (!isAdmin) {
      throw ApiException('Samo administratori mogu pristupiti admin panelu');
    }

    accessToken = result.accessToken;
    refreshToken = result.refreshToken;
    userId = result.userId;
    notifyListeners();
  }

  Future<void> logout() async {
    final token = accessToken;
    final refresh = refreshToken;
    if (token != null && refresh != null && refresh.isNotEmpty) {
      // Revoke the refresh token on the server, not just locally.
      await AuthService.logout(ApiConfig.baseUrl, token, refresh);
    }
    accessToken = null;
    refreshToken = null;
    userId = null;
    notifyListeners();
  }

  String get fullName =>
      accessToken == null ? '' : AuthService.fullNameFromToken(accessToken!);
}
