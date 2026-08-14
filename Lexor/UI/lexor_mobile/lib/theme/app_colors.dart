import 'package:flutter/material.dart';

/// Central color palette for the mobile app — no hard-coded hex values across screens.
class AppColors {
  // Brand
  static const Color primary = Color(0xFF1A237E);
  static const Color primarySoftBg = Color(0xFFE8EAF6);

  // Success / paid / approved
  static const Color success = Color(0xFF43A047);
  static const Color successDark = Color(0xFF2E7D32);
  static const Color successBg = Color(0xFFE8F5E9);

  // Warning / pending
  static const Color warning = Color(0xFFF57C00);
  static const Color warningDark = Color(0xFFE65100);
  static const Color warningBg = Color(0xFFFFF3E0);

  // Error / rejected
  static const Color error = Color(0xFFC62828);
  static const Color errorDark = Color(0xFFB71C1C);
  static const Color errorBg = Color(0xFFFFEBEE);
  static const Color errorBannerBg = Color(0xFFFDECEA);
  static const Color errorBannerBorder = Color(0xFFF5C6C2);

  // Neutral
  static const Color neutralBg = Color(0xFFF5F5F5);
  static const Color neutralFg = Color(0xFF757575);

  // Info / accents
  static const Color info = Color(0xFF1976D2);
  static const Color infoBg = Color(0xFFE3F2FD);
}
