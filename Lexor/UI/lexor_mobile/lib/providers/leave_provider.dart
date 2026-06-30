import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lexor_mobile/api_client.dart';
import 'package:lexor_mobile/models/leave_recent_activity_response.dart';
import 'package:lexor_mobile/models/leave_response.dart';
import 'package:lexor_mobile/models/leave_update_request.dart';
import 'package:lexor_shared/lexor_shared.dart';

class LeaveProvider extends ChangeNotifier {
  LeaveRecentActivityResponse? leaveRecentActivityResponse;
  List<LeaveResponse> leaves = [];
  bool isLoading = false;
  String? error;

  Future<void> fetchLatestLeave() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await ApiClient.get(
        '/Leaves',
        query: {'pageSize': '1', 'sortBy': 'Id desc'},
      );
      final items = data['items'] as List;
      leaveRecentActivityResponse = items.isNotEmpty
          ? LeaveRecentActivityResponse.fromJson(items[0])
          : null;
    } catch (e) {
      error = messageFor(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  int _page = 1;
  bool hasMore = true;
  static const int _pageSize = 10;

  Future<void> fetchLeaves({
    String? stateFilter,
    bool reset = false,
    int? year,
    int? month,
  }) async {
    if (reset) {
      _page = 1;
      hasMore = true;
      leaves = [];
    }

    isLoading = true;
    error = null;
    notifyListeners();

    Map<String, String> query;
    if (year == null && month == null) {
      query = {
        'sortBy': 'DateFrom desc',
        'pageSize': '$_pageSize',
        'page': '$_page',
      };
      if (stateFilter != null) query['state'] = stateFilter;
    } else {
      query = {
        'fromDate': DateFormat('yyyy-MM-dd').format(DateTime(year!, month!, 1)),
        'toDate': DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime(year!, month! + 1, 0)),
      };
    }

    try {
      final data = await ApiClient.get('/Leaves', query: query);
      final items = (data['items'] as List)
          .map((item) => LeaveResponse.fromJson(item))
          .toList();
      if (items.length < _pageSize) hasMore = false;
      leaves = [...leaves, ...items];
      _page++;
    } catch (e) {
      error = messageFor(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createLeave({
    required int leaveTypeId,
    required DateTime dateFrom,
    required DateTime dateTo,
    required String reason,
  }) async {
    await ApiClient.post(
      '/Leaves',
      body: {
        'leaveTypeId': leaveTypeId,
        'dateFrom': DateFormat('yyyy-MM-dd').format(dateFrom),
        'dateTo': DateFormat('yyyy-MM-dd').format(dateTo),
        'reason': reason,
      },
    );
  }

  Future<void> updateLeave(
    LeaveUpdateRequest leaveUpdateRequest,
    int id,
  ) async {
    await ApiClient.put('/Leaves/$id', body: leaveUpdateRequest.toJson());
  }
}
