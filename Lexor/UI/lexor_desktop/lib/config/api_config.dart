/// Centralna konfiguracija za pristup backend API-ju (desktop aplikacija).
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5170',
  );
}
