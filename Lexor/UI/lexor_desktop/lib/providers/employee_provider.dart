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

Future<List<RefOption>> fetchEmployeeOptions() async {
  final uri = Uri.parse(
    '${ApiConfig.baseUrl}/Employees',
  ).replace(queryParameters: {'page': '1', 'pageSize': '1000', 'sortBy': 'Id'});
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
  final data = jsonDecode(res.body);
  return (data['items'] as List).map((e) {
    final user = e['user'] as Map<String, dynamic>?;
    final name = '${user?['firstName'] ?? ''} ${user?['lastName'] ?? ''}'
        .trim();
    return RefOption(e['id'] as int, name);
  }).toList();
}
