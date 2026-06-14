import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lexor_mobile/models/leave_response.dart';
import 'package:lexor_mobile/providers/auth_provider.dart';

class LeaveTypeProvider extends ChangeNotifier {
  static const String _baseUrl = 'http://10.0.2.2:5170';
  List<LeaveTypeResponse> leaveTypes = [];

  Future<void> fetchLeaveTypes() async {
    print('fetchLeaveTypes called');
    var uri = Uri.parse('${_baseUrl}/LeaveTypes');
    try {
      var response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer ${AuthProvider.accessToken}'},
      );

      print('LeaveTypes status: ${response.statusCode}');
      print('LeaveTypes body: ${response.body}');

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        var items = data['items'] as List;
        leaveTypes = items.map((e) => LeaveTypeResponse.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      print('LeaveTypes error: $e');
    }
  }
}
