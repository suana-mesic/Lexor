import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lexor_desktop/config/api_config.dart';
import 'package:lexor_desktop/models/news_response.dart';
import 'package:lexor_desktop/providers/auth_provider.dart';
import 'package:lexor_shared/lexor_shared.dart';

class NewsProvider extends ChangeNotifier {
  static const String _baseUrl = ApiConfig.baseUrl;

  List<NewsResponse> news = [];
  bool isLoading = false;
  String? error;

  Map<String, String> _headers() => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${AuthProvider.accessToken}',
  };

  Future<void> fetch() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final uri = Uri.parse('$_baseUrl/News').replace(
        queryParameters: {'sortBy': 'PublishedAt desc', 'pageSize': '100'},
      );
      final res = await http.get(uri, headers: _headers());
      if (res.statusCode == 200) {
        final items = (jsonDecode(res.body)['items'] as List?) ?? [];
        news = items
            .map((e) => NewsResponse.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        error = ApiError.fromResponse(res);
      }
    } catch (e) {
      error = ApiError.fromException(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Returns null on success, or an error message to show the user.
  Future<String?> save({
    int? id,
    required String title,
    required String content,
    String? imageBase64,
  }) async {
    final body = jsonEncode({
      'title': title,
      'content': content,
      'imageBase64': imageBase64,
    });
    try {
      final res = id == null
          ? await http.post(
              Uri.parse('$_baseUrl/News'),
              headers: _headers(),
              body: body,
            )
          : await http.put(
              Uri.parse('$_baseUrl/News/$id'),
              headers: _headers(),
              body: body,
            );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        await fetch();
        return null;
      }
      return ApiError.fromResponse(res);
    } catch (e) {
      return ApiError.fromException(e);
    }
  }

  Future<String?> remove(int id) async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/News/$id'),
        headers: _headers(),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        await fetch();
        return null;
      }
      return ApiError.fromResponse(res);
    } catch (e) {
      return ApiError.fromException(e);
    }
  }

  void reset() {
    news = [];
    isLoading = false;
    error = null;
    notifyListeners();
  }
}
