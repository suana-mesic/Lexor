import 'package:flutter/material.dart';
import 'package:lexor_mobile/theme/app_colors.dart';

/// Prikaz greške sa ikonom, porukom i dugmetom za ponovni pokušaj.
/// Poruka treba biti razumljiva korisniku (vidi `ApiError` iz lexor_shared).
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Pokušaj ponovo'),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
