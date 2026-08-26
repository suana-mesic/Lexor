import 'package:flutter/material.dart';
import 'package:lexor_desktop/helpers/image_decode.dart';
import 'package:lexor_desktop/theme/app_colors.dart';

/// Profile photo shown next to a person's name in tables and lists (guideline 6).
///
/// List endpoints send a downscaled thumbnail rather than the full picture, and not everyone
/// has uploaded one — so this falls back to the person's initials. Kept in one widget so every
/// list renders the same avatar instead of repeating the fallback logic.
class PersonAvatar extends StatelessWidget {
  final String fullName;
  final String? thumbnailBase64;
  final double radius;

  const PersonAvatar({
    super.key,
    required this.fullName,
    required this.thumbnailBase64,
    this.radius = 16,
  });

  static String initialsOf(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final thumb = thumbnailBase64;
    if (thumb != null && thumb.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(cachedImageBytes(thumb)),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary,
      child: Text(
        initialsOf(fullName),
        style: TextStyle(color: Colors.white, fontSize: radius * 0.75),
      ),
    );
  }
}
