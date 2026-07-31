import 'package:flutter/material.dart';
import 'package:lexor_desktop/helpers/image_decode.dart';
import 'package:lexor_desktop/providers/account_provider.dart';
import 'package:lexor_desktop/providers/auth_provider.dart';
import 'package:lexor_desktop/theme/app_colors.dart';
import 'package:provider/provider.dart';

/// Gornja traka stranice — naslov lijevo, ime administratora i avatar desno.
class AppHeader extends StatelessWidget {
  final String title;

  const AppHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountProvider>().account;
    final authName = context.watch<AuthProvider>().fullName;
    final displayName = (account?.fullName.trim().isNotEmpty ?? false)
        ? account!.fullName
        : (authName.trim().isEmpty ? 'Admin Korisnik' : authName);
    final initial = displayName.trim().isNotEmpty
        ? displayName.trim()[0].toUpperCase()
        : 'A';

    ImageProvider? avatarImage;
    final img = account?.profileImageBase64;
    if (img != null && img.isNotEmpty) {
      try {
        avatarImage = MemoryImage(cachedImageBytes(img));
      } catch (_) {
        avatarImage = null;
      }
    }

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary,
            backgroundImage: avatarImage,
            child: avatarImage == null
                ? Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
