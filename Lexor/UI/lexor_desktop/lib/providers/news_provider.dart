import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lexor_desktop/config/api_config.dart';
import 'package:lexor_desktop/models/news_response.dart';
import 'package:lexor_desktop/providers/auth_provider.dart';
import 'package:lexor_shared/lexor_shared.dart';

class NewsProvider extends ChangeNotifier {
  static const String _baseUrl = ApiConfig.baseUrl;

  static const int pageSize = 6;

  List<NewsResponse> news = [];
  bool isLoading = false;
  String? error;
  int page = 1;
  int totalCount = 0;

  int get totalPages => totalCount <= 0 ? 1 : ((totalCount + pageSize - 1) ~/ pageSize);
  bool get hasPrev => page > 1;
  bool get hasNext => page < totalPages;

  Map<String, String> _headers() => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${AuthProvider.accessToken}',
  };

  Future<void> fetch({int? goToPage}) async {
    if (goToPage != null) page = goToPage;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final uri = Uri.parse('$_baseUrl/News').replace(
        queryParameters: {
          'sortBy': 'PublishedAt desc',
          'page': '$page',
          'pageSize': '$pageSize',
          'includeTotalCount': 'true',
        },
      );
      final res = await http.get(uri, headers: _headers());
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final items = (body['items'] as List?) ?? [];
        news = items
            .map((e) => NewsResponse.fromJson(e as Map<String, dynamic>))
            .toList();
        totalCount = (body['totalCount'] as int?) ?? news.length;
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

  Future<void> nextPage() async {
    if (hasNext) await fetch(goToPage: page + 1);
  }

  Future<void> prevPage() async {
    if (hasPrev) await fetch(goToPage: page - 1);
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
        // A newly created announcement is newest, so jump to the first page; an edit
        // keeps the current page.
        await fetch(goToPage: id == null ? 1 : page);
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
        // Deleting the last item on a page leaves it empty — step back one page.
        if (news.isEmpty && page > 1) await fetch(goToPage: page - 1);
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
    page = 1;
    totalCount = 0;
    notifyListeners();
  }
}
