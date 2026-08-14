import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lexor_desktop/config/api_config.dart';
import 'package:lexor_desktop/models/payroll_dashboard_response.dart';
import 'package:lexor_desktop/providers/auth_provider.dart';
import 'package:lexor_shared/lexor_shared.dart';

class PayrollDashboardProvider extends ChangeNotifier {
  PayrollDashboardResponse? data;
  bool isLoading = false;
  String? error;

  Future<void> fetch() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/PayrollDashboard'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthProvider.accessToken}',
        },
      );

      if (res.statusCode == 200) {
        data = PayrollDashboardResponse.fromJson(jsonDecode(res.body));
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

  void reset() {
    data = null;
    isLoading = false;
    error = null;
    notifyListeners();
  }
}
