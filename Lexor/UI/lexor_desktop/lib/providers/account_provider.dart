import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lexor_desktop/config/api_config.dart';
import 'package:lexor_desktop/models/account_response.dart';
import 'package:lexor_desktop/providers/auth_provider.dart';
import 'package:lexor_shared/lexor_shared.dart';

class AccountProvider extends ChangeNotifier {
  static const String _baseUrl = ApiConfig.baseUrl;

  AccountResponse? account;
  bool isLoading = false;
  String? error;

  Map<String, String> _headers() => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${AuthProvider.accessToken}',
  };

  Future<void> fetch() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final res = await http.get(Uri.parse('$_baseUrl/Account'), headers: _headers());
      if (res.statusCode == 200) {
        account = AccountResponse.fromJson(jsonDecode(res.body));
      } else {
        error = ApiError.fromResponse(res);
      }
    } catch (e) {
      error = ApiError.fromException(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Returns null on success, or an error message.
  Future<String?> update({
    required String username,
    required String email,
    required String phoneNumber,
    String? profileImageBase64,
  }) async {
    try {
      final res = await http.put(
        Uri.parse('$_baseUrl/Account'),
        headers: _headers(),
        body: jsonEncode({
          'username': username,
          'email': email,
          'phoneNumber': phoneNumber,
          'profileImageBase64': profileImageBase64,
        }),
      );
      if (res.statusCode == 200) {
        account = AccountResponse.fromJson(jsonDecode(res.body));
        notifyListeners();
        return null;
      }
      return ApiError.fromResponse(res);
    } catch (e) {
      return ApiError.fromException(e);
    }
  }

  // Returns null on success, or an error message.
  Future<String?> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
      final res = await http.put(
        Uri.parse('$_baseUrl/Account/change-password'),
        headers: _headers(),
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
          'confirmNewPassword': confirmNewPassword,
        }),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) return null;
      return ApiError.fromResponse(res);
    } catch (e) {
      return ApiError.fromException(e);
    }
  }

  void reset() {
    account = null;
    isLoading = false;
    error = null;
    notifyListeners();
  }
}
