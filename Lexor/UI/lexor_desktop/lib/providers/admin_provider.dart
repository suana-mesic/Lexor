import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lexor_desktop/config/api_config.dart';
import 'package:lexor_desktop/models/admin_role_response.dart';
import 'package:lexor_desktop/models/admin_stats_response.dart';
import 'package:lexor_desktop/models/admin_user_response.dart';
import 'package:lexor_desktop/providers/auth_provider.dart';
import 'package:lexor_shared/lexor_shared.dart';

/// Administrator-only data: user list/management, roles overview and system stats.
class AdminProvider extends ChangeNotifier {
  static const String _baseUrl = ApiConfig.baseUrl;

  List<AdminUserResponse> users = [];

  /// Roles shown on the roles screen — narrowed by [roleSearchTerm].
  List<AdminRoleResponse> roles = [];

  /// Every role, regardless of the search term. Kept separate because the users screen
  /// uses it to populate its role dropdowns, which must never be narrowed by a search
  /// the user typed on the roles screen.
  List<AdminRoleResponse> roleOptions = [];

  /// Active role-name search; empty means "no filter".
  String roleSearchTerm = '';

  AdminStatsResponse? stats;
  bool isLoading = false;
  String? error;

  // Remember the last applied user filters so mutations re-fetch the same view.
  String? _fName;
  String? _fRole;
  String? _fStatus;

  Map<String, String> _headers() => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${AuthProvider.accessToken}',
  };

  Future<void> fetchUsers({String? name, String? roleName, String? status}) async {
    _fName = name;
    _fRole = roleName;
    _fStatus = status;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final params = <String, String>{'pageSize': '100', 'sortBy': 'FirstName'};
      if (name != null && name.trim().isNotEmpty) params['name'] = name.trim();
      if (roleName != null && roleName.isNotEmpty) params['roleName'] = roleName;
      if (status != null && status.isNotEmpty) params['activityStatus'] = status;
      final uri = Uri.parse('$_baseUrl/Users').replace(queryParameters: params);
      final res = await http.get(uri, headers: _headers());
      if (res.statusCode == 200) {
        final items = (jsonDecode(res.body)['items'] as List?) ?? [];
        users = items
            .map((e) => AdminUserResponse.fromJson(e as Map<String, dynamic>))
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

  /// Loads the role list from the server, applying [roleSearchTerm] when one is set.
  /// With no search term a single request fills both lists; with a term the unfiltered
  /// [roleOptions] is left alone (or fetched once) so the users screen keeps a complete
  /// dropdown while the roles screen shows only the matches.
  Future<void> fetchRoles() async {
    try {
      final filtered = await _getRoles(nameFilter: roleSearchTerm);
      if (filtered == null) return;
      roles = filtered;

      if (roleSearchTerm.isEmpty) {
        roleOptions = filtered;
      } else if (roleOptions.isEmpty) {
        roleOptions = await _getRoles(nameFilter: '') ?? roleOptions;
      }
      notifyListeners();
    } catch (_) {
      // Roles are auxiliary (dropdown source); ignore transient errors.
    }
  }

  /// Applies a role-name search. Server-side, so the filter matches what the API returns.
  Future<void> searchRoles(String term) async {
    roleSearchTerm = term.trim();
    await fetchRoles();
  }

  /// Single GET /Roles call. Returns null when the request fails, so callers can keep
  /// whatever they already had on screen rather than blanking it out.
  Future<List<AdminRoleResponse>?> _getRoles({required String nameFilter}) async {
    final uri = Uri.parse('$_baseUrl/Roles').replace(queryParameters: {
      'pageSize': '100',
      'sortBy': 'Id',
      if (nameFilter.isNotEmpty) 'name': nameFilter,
    });
    final res = await http.get(uri, headers: _headers());
    if (res.statusCode != 200) return null;

    final items = (jsonDecode(res.body)['items'] as List?) ?? [];
    return items
        .map((e) => AdminRoleResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> fetchStats() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final res = await http.get(Uri.parse('$_baseUrl/Users/stats'), headers: _headers());
      if (res.statusCode == 200) {
        stats = AdminStatsResponse.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>,
        );
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

  Future<String?> changeRole(int userId, int roleId) => _mutate(
    () => http.put(
      Uri.parse('$_baseUrl/Users/$userId/role'),
      headers: _headers(),
      body: jsonEncode({'roleId': roleId}),
    ),
  );

  Future<String?> setActive(int userId, bool isActive) => _mutate(
    () => http.patch(
      Uri.parse('$_baseUrl/Users/$userId/${isActive ? 'activate' : 'deactivate'}'),
      headers: _headers(),
    ),
  );

  Future<String?> updateRole(
    int roleId, {
    required String description,
    required bool isActive,
  }) async {
    try {
      final res = await http.put(
        Uri.parse('$_baseUrl/Roles/$roleId'),
        headers: _headers(),
        body: jsonEncode({'description': description, 'isActive': isActive}),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        await fetchRoles();
        return null;
      }
      return ApiError.fromResponse(res);
    } catch (e) {
      return ApiError.fromException(e);
    }
  }

  // Runs a mutation; on success re-fetches the current user view. Returns null or a message.
  Future<String?> _mutate(Future<http.Response> Function() action) async {
    try {
      final res = await action();
      if (res.statusCode >= 200 && res.statusCode < 300) {
        await fetchUsers(name: _fName, roleName: _fRole, status: _fStatus);
        return null;
      }
      return ApiError.fromResponse(res);
    } catch (e) {
      return ApiError.fromException(e);
    }
  }

  void reset() {
    users = [];
    roles = [];
    roleOptions = [];
    roleSearchTerm = '';
    stats = null;
    isLoading = false;
    error = null;
    _fName = _fRole = _fStatus = null;
    notifyListeners();
  }
}
