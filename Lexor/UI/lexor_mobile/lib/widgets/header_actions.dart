import 'package:flutter/material.dart';
import 'package:lexor_mobile/screens/profile_screen.dart';
import 'package:lexor_mobile/widgets/notifications_bell.dart';

/// Shared header actions (notifications bell + profile) used across the tab headers,
/// so every tab — not just Home — can open notifications and the profile.
class HeaderActions extends StatelessWidget {
  const HeaderActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const NotificationBell(),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 26),
        ),
      ],
    );
  }
}
