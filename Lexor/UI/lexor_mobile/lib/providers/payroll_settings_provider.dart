import 'package:flutter/material.dart';
import 'package:lexor_mobile/api_client.dart';
import 'package:lexor_shared/lexor_shared.dart';

class PayrollSettingsProvider extends ChangeNotifier {
  // Default Mon-Fri (bits 0-4 set = 31)
  int workDaysMask = 31;
  String? error;

  bool isWorkDay(DateTime day) {
    // Flutter weekday: Mon=1 ... Sat=6, Sun=7
    // Backend bit:     Mon=0 ... Sat=5, Sun=6
    final bitPosition = day.weekday == 7 ? 6 : day.weekday - 1;
    return (workDaysMask & (1 << bitPosition)) != 0;
  }

  Future<void> fetchCurrentSettings() async {
    error = null;
    try {
      final data = await ApiClient.get('/PayrollSettings/current');
      workDaysMask = (data['workDaysMask'] as num).toInt();
    } catch (e) {
      // Keep the default mask as a fallback, but surface the failure.
      error = messageFor(e);
    } finally {
      notifyListeners();
    }
  }
}
