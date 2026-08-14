import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lexor_desktop/config/api_config.dart';
import 'package:lexor_desktop/models/employee_response.dart';
import 'package:lexor_desktop/providers/auth_provider.dart';
import 'package:lexor_desktop/providers/base_provider.dart';
import 'package:lexor_shared/lexor_shared.dart';

class EmployeeProvider extends BaseProvider<EmployeeResponse> {
  EmployeeProvider() : super('Employees');

  @override
  EmployeeResponse fromJson(data) => EmployeeResponse.fromJson(data);

  /// Soft-delete via the dedicated PATCH endpoint (Employees/{id}/deactivate).
  Future<EmployeeResponse> deactivate(int id) async {
    final res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/Employees/$id/deactivate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthProvider.accessToken}',
      },
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(ApiError.fromResponse(res));
    }
    return EmployeeResponse.fromJson(jsonDecode(res.body));
  }
}

/// Employee id + name list for autocomplete pickers. Uses the dedicated lookup endpoint
/// (not the HR-only Employees CRUD) so back-office roles other than HR — accounting on the
/// reports screen, admin on the RFID screen — can populate the picker too.
Future<List<RefOption>> fetchEmployeeOptions() async {
  final uri = Uri.parse('${ApiConfig.baseUrl}/EmployeeLookup');
  final res = await http.get(
    uri,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${AuthProvider.accessToken}',
    },
  );
  if (res.statusCode != 200) {
    throw ApiException(ApiError.fromResponse(res));
  }
  final data = jsonDecode(res.body) as List;
  return data
      .map((e) => RefOption(e['id'] as int, (e['fullName'] as String?) ?? ''))
      .toList();
}
