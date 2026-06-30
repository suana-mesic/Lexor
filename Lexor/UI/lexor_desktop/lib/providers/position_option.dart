import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lexor_desktop/config/api_config.dart';
import 'package:lexor_desktop/providers/auth_provider.dart';
import 'package:lexor_shared/lexor_shared.dart';

/// Position option carrying its DepartmentId so the employee form can filter
/// positions by the selected department (a position belongs to one department).
class PositionOption {
  final int id;
  final String name;
  final int departmentId;

  const PositionOption({
    required this.id,
    required this.name,
    required this.departmentId,
  });
}

Future<List<PositionOption>> fetchPositionOptions() async {
  final uri = Uri.parse('${ApiConfig.baseUrl}/Positions').replace(
    queryParameters: {'page': '1', 'pageSize': '1000', 'sortBy': 'Name'},
  );
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
  return (data['items'] as List)
      .map((e) => PositionOption(
            id: e['id'] as int,
            name: (e['name'] as String?) ?? '',
            departmentId: e['departmentId'] as int? ?? 0,
          ))
      .toList();
}
