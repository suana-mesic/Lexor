import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lexor_desktop/config/api_config.dart';
import 'package:lexor_desktop/models/contract_response.dart';
import 'package:lexor_desktop/providers/auth_provider.dart';
import 'package:lexor_desktop/providers/base_provider.dart';
import 'package:lexor_shared/lexor_shared.dart';

class ContractProvider extends BaseProvider<ContractResponse> {
  ContractProvider() : super('Contracts');

  @override
  ContractResponse fromJson(data) => ContractResponse.fromJson(data);

  /// Atomically closes the current active contract and inserts a new one
  /// on the server (single transaction).
  Future<ContractResponse> replaceActive(
    int employeeId,
    Map<String, dynamic> request,
  ) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/Contracts/employee/$employeeId/replace'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthProvider.accessToken}',
      },
      body: jsonEncode(request),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(ApiError.fromResponse(res));
    }
    return ContractResponse.fromJson(jsonDecode(res.body));
  }
}
