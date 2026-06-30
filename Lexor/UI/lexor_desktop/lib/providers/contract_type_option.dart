import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lexor_desktop/config/api_config.dart';
import 'package:lexor_desktop/providers/auth_provider.dart';
import 'package:lexor_shared/lexor_shared.dart';

/// Contract type option with the EndDateRequired flag so the UI can show/hide
/// the "end date" field based on the chosen type (e.g. fixed-term vs indefinite).
class ContractTypeOption {
  final int id;
  final String name;
  final bool endDateRequired;

  const ContractTypeOption({
    required this.id,
    required this.name,
    required this.endDateRequired,
  });
}

Future<List<ContractTypeOption>> fetchContractTypeOptions() async {
  final uri = Uri.parse('${ApiConfig.baseUrl}/ContractTypes').replace(
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
      .map((e) => ContractTypeOption(
            id: e['id'] as int,
            name: (e['name'] as String?) ?? '',
            endDateRequired: e['endDateRequired'] as bool? ?? false,
          ))
      .toList();
}
