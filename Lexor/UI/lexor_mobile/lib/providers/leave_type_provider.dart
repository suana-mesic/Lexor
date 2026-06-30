import 'package:flutter/material.dart';
import 'package:lexor_mobile/api_client.dart';
import 'package:lexor_mobile/models/leave_response.dart';
import 'package:lexor_shared/lexor_shared.dart';

class LeaveTypeProvider extends ChangeNotifier {
  List<LeaveTypeResponse> leaveTypes = [];
  String? error;

  Future<void> fetchLeaveTypes() async {
    error = null;
    try {
      final data = await ApiClient.get('/LeaveTypes');
      final items = data['items'] as List;
      leaveTypes = items.map((e) => LeaveTypeResponse.fromJson(e)).toList();
    } catch (e) {
      error = messageFor(e);
    } finally {
      notifyListeners();
    }
  }
}
