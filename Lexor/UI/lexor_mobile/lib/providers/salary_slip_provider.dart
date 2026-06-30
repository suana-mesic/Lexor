import 'package:flutter/material.dart';
import 'package:lexor_mobile/api_client.dart';
import 'package:lexor_mobile/models/salary_slip_recent_activity_response.dart';
import 'package:lexor_mobile/models/salary_slip_response.dart';
import 'package:lexor_shared/lexor_shared.dart';

class SalarySlipProvider extends ChangeNotifier {
  SalarySlipRecentActivityResponse? salarySlipRecentActivityResponse;
  List<SalarySlipResponse> salarySlips = [];
  bool isLoading = false;
  String? error;
  int _page = 1;
  bool hasMore = true;
  static const int _pageSize = 10;

  Future<void> fetchLatestSalarySlip() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await ApiClient.get(
        '/SalarySlips',
        query: {'pageSize': '1', 'sortBy': 'Id desc'},
      );
      final items = data['items'] as List;
      if (items.isNotEmpty) {
        salarySlipRecentActivityResponse =
            SalarySlipRecentActivityResponse.fromJson(items[0]);
      }
    } catch (e) {
      error = messageFor(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSalarySlips({bool reset = false}) async {
    if (reset) {
      _page = 1;
      hasMore = true;
      salarySlips = [];
    }
    if (!hasMore) return;

    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await ApiClient.get(
        '/SalarySlips',
        query: {
          'pageSize': '$_pageSize',
          'page': '$_page',
          'sortBy': 'Id desc',
        },
      );
      final items = (data['items'] as List)
          .map((item) => SalarySlipResponse.fromJson(item))
          .toList();
      if (items.length < _pageSize) hasMore = false;
      salarySlips = [...salarySlips, ...items];
      _page++;
    } catch (e) {
      error = messageFor(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
