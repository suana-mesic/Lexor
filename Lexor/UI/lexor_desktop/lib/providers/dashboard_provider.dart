import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lexor_desktop/models/dashboard_response.dart';
import 'package:lexor_desktop/providers/auth_provider.dart';
import 'package:lexor_shared/lexor_shared.dart';
import 'package:lexor_desktop/config/api_config.dart';

class DashboardProvider extends ChangeNotifier {
  static const String _baseUrl = ApiConfig.baseUrl;
  DashboardResponse? dashboard;
  bool isLoading = false;
  String? error;
  bool sessionExpired = false;

  Future<void> fetchDashboard() async {
    try {
      isLoading = true;
      error = null;
      sessionExpired = false;
      notifyListeners();

      final uri = Uri.parse('$_baseUrl/Dashboard');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthProvider.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        dashboard = DashboardResponse.fromJson(jsonDecode(response.body));
      } else {
        error = ApiError.fromResponse(response);
        sessionExpired = ApiError.isSessionExpired(response);
        print('Dashboard HTTP error: ${response.statusCode} ${response.body}');
      }
    } catch (e, stack) {
      error = ApiError.fromException(e);
      print('Dashboard exception: $e\n$stack');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
