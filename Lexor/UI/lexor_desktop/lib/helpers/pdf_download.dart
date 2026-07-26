import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:lexor_desktop/config/api_config.dart';
import 'package:lexor_desktop/providers/auth_provider.dart';
import 'package:lexor_shared/lexor_shared.dart';

Future<String?> downloadPdf(String path, String suggestedName) async {
  final res = await http.get(
    Uri.parse('${ApiConfig.baseUrl}$path'),
    headers: {'Authorization': 'Bearer ${AuthProvider.accessToken}'},
  );

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw ApiException(ApiError.fromResponse(res));
  }

  final savePath = await FilePicker.saveFile(
    dialogTitle: 'Sačuvaj PDF',
    fileName: suggestedName,
    type: FileType.custom,
    allowedExtensions: ['pdf'],
  );
  if (savePath == null) return null; // cancelled

  await File(savePath).writeAsBytes(res.bodyBytes);
  return savePath;
}
