import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lexor_desktop/config/api_config.dart';
import 'package:lexor_desktop/models/legal_document_response.dart';
import 'package:lexor_desktop/providers/auth_provider.dart';
import 'package:lexor_desktop/providers/base_provider.dart';
import 'package:lexor_shared/lexor_shared.dart';

class LegalDocumentProvider extends BaseProvider<LegalDocumentResponse> {
  LegalDocumentProvider() : super('LegalDocument');

  @override
  LegalDocumentResponse fromJson(data) => LegalDocumentResponse.fromJson(data);

  Future<void> upload({
    required String name,
    required int categoryId,
    required List<int> bytes,
  }) async {
    await insert({
      'name': name,
      'categoryId': categoryId,
      'fileBase64': base64Encode(bytes),
      'fileSize': bytes.length,
    });
  }

  Future<List<int>> downloadBytes(int id) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/LegalDocument/$id/download'),
      headers: {'Authorization': 'Bearer ${AuthProvider.accessToken}'},
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(ApiError.fromResponse(res));
    }
    return res.bodyBytes;
  }
}
