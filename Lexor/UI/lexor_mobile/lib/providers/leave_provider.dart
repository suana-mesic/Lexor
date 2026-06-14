import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lexor_mobile/models/leave_recent_activity_response.dart';
import 'package:lexor_mobile/models/leave_response.dart';
import 'package:lexor_mobile/models/leave_update_request.dart';
import 'package:lexor_mobile/providers/auth_provider.dart';

class LeaveProvider extends ChangeNotifier {
  LeaveRecentActivityResponse? leaveRecentActivityResponse;
  List<LeaveResponse> leaves = [];
  bool isLoading = false;

  static const String _baseUrl = 'http://10.0.2.2:5170';

  Future<void> fetchLatestLeave() async {
    isLoading = true;
    notifyListeners();

    try {
      var queryParameters = <String, String>{
        'pageSize': '1',
        'sortBy': 'Id desc',
      };
      var uri = Uri.parse(
        '${_baseUrl}/Leaves',
      ).replace(queryParameters: queryParameters);
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
        leaveRecentActivityResponse = LeaveRecentActivityResponse.fromJson(
          items[0],
        );
      }
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
    notifyListeners();

    var queryParameters = <String, String>{};
    try {
      if (year == null && month == null) {
        queryParameters = {
          'sortBy': 'DateFrom desc',
          'pageSize': '$_pageSize',
          'page': '$_page',
        };
        if (stateFilter != null) queryParameters['state'] = stateFilter;
      } else {
        queryParameters = {
          'fromDate': DateFormat(
            'yyyy-MM-dd',
          ).format(DateTime(year!, month!, 1)),
          'toDate': DateFormat(
            'yyyy-MM-dd',
          ).format(DateTime(year!, month! + 1, 0)),
        };
      }
      var uri = Uri.parse(
        '${_baseUrl}/Leaves',
      ).replace(queryParameters: queryParameters);
      var response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthProvider.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        var items = (data['items'] as List)
            .map((item) => LeaveResponse.fromJson(item))
            .toList();
        if (items.length < _pageSize) hasMore = false;
        leaves = [...leaves, ...items];
        _page++;
      }
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
    var uri = Uri.parse('${_baseUrl}/Leaves');
    var body = jsonEncode({
      'leaveTypeId': leaveTypeId,
      'dateFrom': DateFormat('yyyy-MM-dd').format(dateFrom),
      'dateTo': DateFormat('yyyy-MM-dd').format(dateTo),
      'reason': reason,
    });

    var response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthProvider.accessToken}',
      },
      body: body,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      String message = 'Greška pri kreiranju zahtjeva';
      if (response.body.isNotEmpty) {
        try {
          final data = jsonDecode(response.body);
          message = data['message'] ?? message;
        } catch (_) {
          message = response.body;
        }
      }
      throw Exception(message);
    }
  }

  Future<void> updateLeave(
    LeaveUpdateRequest leaveUpdateRequest,
    int id,
  ) async {
    var uri = Uri.parse('${_baseUrl}/Leaves/${id}');

    var response = await http.put(
      uri,
      body: jsonEncode(leaveUpdateRequest.toJson()),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthProvider.accessToken}',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      String message = 'Greška pri ažuriranju zahtjeva';

      if (response.body.isNotEmpty) {
        try {
          final data = jsonDecode(response.body);
          message = data['message'] ?? message;
        } catch (_) {
          message = response.body;
        }
      }
      throw Exception(message);
    }
  }
}
