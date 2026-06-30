/// Typed exception carrying a user-facing message (already humanized via `ApiError`).
/// Providers throw this; the UI reads `.message` (or `messageFor`) — no string parsing.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

/// Returns a user-facing message from any caught error.
/// For [ApiException] it's the carried message; otherwise the default
/// "Exception: " prefix is stripped as a fallback (one place, not 18).
String messageFor(Object error) {
  if (error is ApiException) return error.message;
  return error.toString().replaceFirst('Exception: ', '');
}
