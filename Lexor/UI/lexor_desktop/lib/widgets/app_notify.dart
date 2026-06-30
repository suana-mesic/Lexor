import 'package:flutter/material.dart';
import 'package:lexor_desktop/theme/app_colors.dart';

/// Single place that shows success/error snackbars, so screens don't each
/// re-implement the SnackBar + color logic.
void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.error : AppColors.success,
    ),
  );
}
