import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lexor_mobile/api_client.dart';
import 'package:lexor_mobile/models/attendance_response.dart';
import 'package:lexor_mobile/models/attendance_summary.dart';
import 'package:lexor_shared/lexor_shared.dart';

class AttendanceProvider extends ChangeNotifier {
  AttendanceSummary? summary;
  bool isLoading = false;
  List<AttendanceResponse> attendances = [];
  AttendanceResponse? attendanceById;
  String? error;

  Future<void> fetchSummary() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await ApiClient.get('/Attendances/summary');
      summary = AttendanceSummary.fromJson(data);
    } catch (e) {
      error = messageFor(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAttendances(int year, int month) async {
    isLoading = true;
    error = null;
    notifyListeners();

    final fromDate = DateTime(year, month, 1);
    final toDate = DateTime(year, month + 1, 0);
    try {
      final data = await ApiClient.get(
        '/Attendances',
        query: {
          'fromDate': DateFormat('yyyy-MM-dd').format(fromDate),
          'toDate': DateFormat('yyyy-MM-dd').format(toDate),
          // The calendar needs the whole month at once, not a page of it — without this the
          // server's default page size (10) silently cuts the month short.
          'pageSize': '31',
        },
      );
      final items = data['items'] as List;
      attendances = items
          .map((item) => AttendanceResponse.fromJson(item))
          .toList();
    } catch (e) {
      error = messageFor(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    summary = null;
    attendances = [];
    attendanceById = null;
    isLoading = false;
    error = null;
    notifyListeners();
  }
}
