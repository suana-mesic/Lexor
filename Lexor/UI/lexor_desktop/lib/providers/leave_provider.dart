import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lexor_desktop/config/api_config.dart';
import 'package:lexor_desktop/models/leave_response.dart';
import 'package:lexor_desktop/providers/auth_provider.dart';
import 'package:lexor_desktop/providers/base_provider.dart';
import 'package:lexor_shared/lexor_shared.dart';

class LeaveProvider extends BaseProvider<LeaveResponse> {
  LeaveProvider() : super('Leaves');

  @override
  LeaveResponse fromJson(dynamic data) => LeaveResponse.fromJson(data);

  /// Admin approves a pending request.
  Future<void> approve(int id) => _put('approve/$id');

  /// Admin rejects a pending request; a reason is required by the server.
  Future<void> reject(int id, String reason) =>
      _put('reject/$id', body: {'rejectionReason': reason});

  Future<void> cancel(int id, String? reason) =>
      _put('cancel/$id', body: {'cancellationReason': reason});

  Future<void> _put(String path, {Map<String, dynamic>? body}) async {
    final res = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/Leaves/$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthProvider.accessToken}',
      },
      body: body == null ? null : jsonEncode(body),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(ApiError.fromResponse(res));
    }
  }
}
