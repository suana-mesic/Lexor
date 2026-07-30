import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lexor_desktop/config/api_config.dart';
import 'package:lexor_desktop/models/absence_forecast_response.dart';
import 'package:lexor_desktop/providers/auth_provider.dart';
import 'package:lexor_shared/lexor_shared.dart';

class AbsencePredictionProvider extends ChangeNotifier {
  static const String _baseUrl = ApiConfig.baseUrl;

  AbsenceForecastResponse? forecast;
  bool isLoading = false;
  String? error;
  bool sessionExpired = false;

  Future<void> fetchForecast(DateTime from, DateTime to) async {
    try {
      isLoading = true;
      error = null;
      sessionExpired = false;
      notifyListeners();

      final uri = Uri.parse(
        '$_baseUrl/Prediction/absences?from=${_date(from)}&to=${_date(to)}',
      );
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthProvider.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        forecast = AbsenceForecastResponse.fromJson(jsonDecode(response.body));
      } else {
        error = ApiError.fromResponse(response);
        sessionExpired = ApiError.isSessionExpired(response);
      }
    } catch (e) {
      error = ApiError.fromException(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // API expects a plain yyyy-MM-dd date (DateOnly), so we format it manually.
  String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  void reset() {
    forecast = null;
    isLoading = false;
    error = null;
    sessionExpired = false;
    notifyListeners();
  }
}
