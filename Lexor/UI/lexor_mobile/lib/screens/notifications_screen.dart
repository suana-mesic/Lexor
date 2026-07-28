import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lexor_mobile/providers/notification_provider.dart';
import 'package:lexor_mobile/theme/app_colors.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).fetchNotifications(reset: true);
    });
    _scroll.addListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotificationProvider>(context, listen: true);
    final hasUnread = provider.notifications.any((n) => !n.isRead);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikacije'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: provider.markAllAsRead,
              child: const Text(
                'Pročitaj sve',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _body(provider),
    );
  }

  Widget _body(NotificationProvider provider) {
    if (provider.isLoading && provider.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(provider.error!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: provider.fetchNotifications,
              child: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      );
    }

    if (provider.notifications.isEmpty) {
      return const Center(child: Text('Nema notifikacija.'));
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchNotifications(reset: true),
      child: ListView.separated(
        controller: _scroll,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemCount: provider.notifications.length,
        itemBuilder: (_, i) {
          final n = provider.notifications[i];
          return Container(
            decoration: BoxDecoration(
              color: n.isRead ? Colors.white : AppColors.infoBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: Icon(
                n.isRead
                    ? Icons.notifications_none
                    : Icons.notifications_active,
                color: n.isRead ? Colors.grey : AppColors.info,
              ),
              title: Text(
                n.title,
                style: TextStyle(
                  fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: Text(n.body),
              trailing: Text(
                DateFormat('dd.MM.yyyy\nHH:mm').format(n.createdAt.toLocal()),
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              onTap: n.isRead ? null : () => provider.markAsRead(n.id),
            ),
          );
        },
      ),
    );
  }

  void _onScroll() {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200 &&
        !provider.isLoading &&
        provider.hasMore) {
      provider.fetchNotifications();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }
}
