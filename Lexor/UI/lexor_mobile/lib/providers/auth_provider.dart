import 'package:flutter/material.dart';
import 'package:lexor_mobile/config/api_config.dart';
import 'package:lexor_mobile/auth_store.dart';
import 'package:lexor_mobile/session.dart';
import 'package:lexor_shared/lexor_shared.dart';

class AuthProvider extends ChangeNotifier {
  static String? accessToken;
  int? userId;

  Future<void> login(String username, String password) async {
    final result = await AuthService(ApiConfig.baseUrl).login(username, password);
    accessToken = result.accessToken;
    userId = result.userId;
    await saveToken(result.accessToken);
    resetSessionExpiredGuard();
    notifyListeners();
  }

  String get fullName =>
      accessToken == null ? '' : AuthService.fullNameFromToken(accessToken!);
}
