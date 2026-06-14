import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lexor_mobile/models/salary_slip_recent_activity_response.dart';
import 'package:lexor_mobile/providers/auth_provider.dart';

class SalarySlipProvider extends ChangeNotifier {
  static const String _baseUrl = 'http://10.0.2.2:5170';
  SalarySlipRecentActivityResponse? salarySlipRecentActivityResponse;
  bool isLoading = false;

  Future<void> fetchLatestSalarySlip() async {
    try {
      isLoading = true;
      notifyListeners();
      var uri = Uri.parse(
        '${_baseUrl}/SalarySlips',
      ).replace(queryParameters: {'pageSize': '1', 'sortBy': 'Id desc'});
      var response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthProvider.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        var items = data['items'] as List;
        if (items.isNotEmpty) {
          salarySlipRecentActivityResponse =
              SalarySlipRecentActivityResponse.fromJson(items[0]);
        }
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
