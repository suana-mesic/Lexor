import 'package:flutter/material.dart';
import 'package:lexor_mobile/auth_store.dart';
import 'package:lexor_mobile/providers/auth_provider.dart';
import 'package:lexor_mobile/screens/login_screen.dart';

/// Global navigator key so we can navigate without a BuildContext
/// (e.g. force the user back to login when their session expires).
final navigatorKey = GlobalKey<NavigatorState>();

bool _redirecting = false;

/// Called when an API request returns 401 (expired/invalid token):
/// clears the stored token and returns the user to the login screen.
/// Debounced so several concurrent 401s don't stack multiple redirects.
void handleSessionExpired() {
  if (_redirecting) return;
  _redirecting = true;

  AuthProvider.accessToken = null;
  clearToken();
  navigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}

/// Re-arms the redirect after a successful login.
void resetSessionExpiredGuard() => _redirecting = false;
