import 'package:http/http.dart' as http;
import 'package:lexor_desktop/config/api_config.dart';
import 'package:lexor_desktop/models/rfid_response.dart';
import 'package:lexor_desktop/providers/auth_provider.dart';
import 'package:lexor_desktop/providers/base_provider.dart';
import 'package:lexor_shared/lexor_shared.dart';

class RfidCardProvider extends BaseProvider<RfidResponse> {
  RfidCardProvider() : super('RFID');

  @override
  RfidResponse fromJson(data) => RfidResponse.fromJson(data);

  Future<void> deactivate(int id) async {
    final res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/RFID/$id/deactivate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthProvider.accessToken}',
      },
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(ApiError.fromResponse(res));
    }
  }
}
