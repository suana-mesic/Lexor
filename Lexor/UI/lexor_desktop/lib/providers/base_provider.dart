import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lexor_desktop/config/api_config.dart';
import 'package:lexor_desktop/models/search_result.dart';
import 'package:lexor_desktop/providers/auth_provider.dart';
import 'package:lexor_shared/lexor_shared.dart';

abstract class BaseProvider<T> with ChangeNotifier {
  final String endpoint; // npr. 'Cities'
  BaseProvider(this.endpoint);

  T fromJson(dynamic data);

  Map<String, String> _headers() => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${AuthProvider.accessToken}',
  };

  Future<SearchResult<T>> get({Map<String, dynamic>? filter}) async {
    var url = '${ApiConfig.baseUrl}/$endpoint';
    if (filter != null && filter.isNotEmpty) {
      url = '$url?${_queryString(filter)}';
    }

    final res = await _send(
      () => http.get(Uri.parse(url), headers: _headers()),
    );

    final data = jsonDecode(res.body);
    return SearchResult<T>(
      totalCount: data['totalCount'] as int?,
      items: (data['items'] as List).map((item) => fromJson(item)).toList(),
    );
  }

  Future<T> getById(int id) async {
    final res = await _send(
      () => http.get(
        Uri.parse('${ApiConfig.baseUrl}/$endpoint/$id'),
        headers: _headers(),
      ),
    );
    return fromJson(jsonDecode(res.body));
  }

  Future<T> insert(dynamic request) async {
    final res = await _send(
      () => http.post(
        Uri.parse('${ApiConfig.baseUrl}/$endpoint'),
        headers: _headers(),
        body: jsonEncode(request),
      ),
    );
    return fromJson(jsonDecode(res.body));
  }

  Future<T> update(int id, dynamic request) async {
    final res = await _send(
      () => http.put(
        Uri.parse('${ApiConfig.baseUrl}/$endpoint/$id'),
        headers: _headers(),
        body: jsonEncode(request),
      ),
    );
    return fromJson(jsonDecode(res.body));
  }

  Future<void> remove(int id) async {
    await _send(
      () => http.delete(
        Uri.parse('${ApiConfig.baseUrl}/$endpoint/$id'),
        headers: _headers(),
      ),
    );
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request, {
    bool isRetry = false,
  }) async {
    late http.Response res;
    try {
      res = await request();
    } catch (e) {
      throw ApiException(ApiError.fromException(e));
    }
    if (res.statusCode == 401 && !isRetry) {
      if (await _tryRefresh()) {
        return _send(request, isRetry: true);
      }
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(ApiError.fromResponse(res));
    }
    return res;
  }

  Future<bool> _tryRefresh() async {
    final refresh = AuthProvider.refreshToken;
    if (refresh == null || refresh.isEmpty) return false;
    final result = await AuthService.refresh(ApiConfig.baseUrl, refresh);
    if (result == null) return false;
    AuthProvider.accessToken = result.accessToken;
    AuthProvider.refreshToken = result.refreshToken;
    return true;
  }

  String _queryString(Map<String, dynamic> params) {
    final parts = <String>[];

    for (final entry in params.entries) {
      if (entry.value != null) {
        parts.add(
          '${entry.key}=${Uri.encodeComponent(entry.value.toString())}',
        );
      }
    }
    return parts.join('&');
  }
}

/// Opcija za FK dropdown (npr. država pri dodavanju grada).
class RefOption {
  final int id;
  final String name;
  const RefOption(this.id, this.name);
}

/// Dohvata sve zapise referentne tabele kao opcije za FK dropdown (id + name).
/// `endpoint` ovdje uključuje vodeću kosu crtu (npr. '/Countries').
Future<List<RefOption>> fetchRefOptions(String endpoint) async {
  final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint').replace(
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
      .map((e) => RefOption(e['id'] as int, e['name'] as String? ?? ''))
      .toList();
}
