import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lexor_mobile/models/attendance_response.dart';
import 'package:lexor_mobile/models/attendance_summary.dart';
import 'package:lexor_mobile/providers/auth_provider.dart';

class AttendanceProvider extends ChangeNotifier {
  AttendanceSummary? summary;
  bool isLoading = false;
  List<AttendanceResponse> attendances = [];
  AttendanceResponse? attendanceById;

  static const String _baseUrl = 'http://10.0.2.2:5170';

  Future<void> fetchSummary() async {
    isLoading = true;
    notifyListeners();

    try {
      var uri = Uri.parse('${_baseUrl}/Attendances/summary');
      var response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthProvider.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        summary = AttendanceSummary.fromJson(data);
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAttendances(int year, int month) async {
    isLoading = true;
    notifyListeners();

    final fromDate = DateTime(year, month, 1);
    final toDate = DateTime(year, month + 1, 0);

    try {
      var uri = Uri.parse('${_baseUrl}/Attendances').replace(
        queryParameters: {
          'fromDate': DateFormat('yyyy-MM-dd').format(fromDate),
          'toDate': DateFormat('yyyy-MM-dd').format(toDate),
        },
      );
      var response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthProvider.accessToken}',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List;
        attendances = items
            .map((item) => AttendanceResponse.fromJson(item))
            .toList();
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Future<void> fetchAttendanceByDate(int year, int month, int day) async {
  //   isLoading = true;
  //   notifyListeners();

  //   final fromDate = DateTime(year, month, day);
  //   final toDate = DateTime(year, month + 1, 0);

  //   try {
  //     var uri = Uri.parse('${_baseUrl}/Attendances').replace(
  //       queryParameters: {
  //         'fromDate': DateFormat('yyyy-MM-dd').format(fromDate),
  //         'toDate': DateFormat('yyyy-MM-dd').format(toDate),

  //       },
  //     );
  //     var response = await http.get(
  //       uri,
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Authorization': 'Bearer ${AuthProvider.accessToken}',
  //       },
  //     );
  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       attendanceById = AttendanceResponse.fromJson(data);
  //     }
  //   } finally {
  //     isLoading = false;
  //     notifyListeners();
  //   }
  // }
}
