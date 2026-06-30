import 'package:flutter/material.dart';
import 'package:lexor_mobile/theme/app_colors.dart';

/// Kompaktni inline banner za greške na ekranima koji prikazuju više sekcija
/// (npr. početna, prisustvo) — ne sakriva ostatak sadržaja, samo upozorava.
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorBanner({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorBannerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorBannerBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.errorDark, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Pokušaj ponovo'),
          ),
        ],
      ),
    );
  }
}
