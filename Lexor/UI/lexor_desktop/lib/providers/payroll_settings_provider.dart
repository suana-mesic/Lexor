import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lexor_desktop/config/api_config.dart';
import 'package:lexor_desktop/models/payroll_settings_response.dart';
import 'package:lexor_desktop/providers/auth_provider.dart';
import 'package:lexor_desktop/providers/base_provider.dart';
import 'package:lexor_shared/lexor_shared.dart';

class PayrollSettingsProvider extends BaseProvider<PayrollSettingsResponse> {
  PayrollSettingsProvider() : super('PayrollSettings');

  @override
  PayrollSettingsResponse fromJson(data) =>
      PayrollSettingsResponse.fromJson(data);

  Future<PayrollSettingsResponse?> getCurrent() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/PayrollSettings/current'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthProvider.accessToken}',
      },
    );
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) throw ApiException(ApiError.fromResponse(res));

    return PayrollSettingsResponse.fromJson(jsonDecode(res.body));
  }
}
