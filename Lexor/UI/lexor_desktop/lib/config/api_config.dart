/// Central configuration for reaching the backend API (desktop app).
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5170',
  );
}
