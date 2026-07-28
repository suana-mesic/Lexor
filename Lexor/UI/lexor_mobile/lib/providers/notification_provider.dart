import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lexor_mobile/api_client.dart';
import 'package:lexor_mobile/models/notification_response.dart';
import 'package:lexor_shared/lexor_shared.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationResponse> notifications = [];
  int unreadCount = 0;
  bool isLoading = false;
  String? error;
  int _page = 1;
  static const int _pageSize = 20;
  bool hasMore = true;

  Timer? _pollTimer;

  void startPolling() {
    refreshUnreadCount();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => refreshUnreadCount(),
    );
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> refreshUnreadCount() async {
    try {
      final data = await ApiClient.get('/Notifications/unread-count');
      unreadCount = data as int;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchNotifications({bool reset = false}) async {
    if (reset) {
      _page = 1;
      hasMore = true;
      notifications = [];
    }
    if (!hasMore) return;

    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await ApiClient.get(
        '/Notifications',
        query: {
          'sortBy': 'CreatedAt desc',
          'pageSize': '$_pageSize',
          'page': '$_page',
        },
      );
      final items = (data['items'] as List)
          .map((e) => NotificationResponse.fromJson(e))
          .toList();
      if (items.length < _pageSize) hasMore = false;
      notifications = [...notifications, ...items];
      _page++;
    } catch (e) {
      error = messageFor(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await ApiClient.put('/Notifications/$id/read');
      final i = notifications.indexWhere((n) => n.id == id);
      if (i != -1 && !notifications[i].isRead) {
        notifications[i].isRead = true;
        if (unreadCount > 0) unreadCount--;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await ApiClient.put('/Notifications/read-all');
      for (final n in notifications) {
        n.isRead = true;
      }
      unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }

  void reset() {
    stopPolling();
    notifications = [];
    unreadCount = 0;
    isLoading = false;
    error = null;
    _page = 1;
    hasMore = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
