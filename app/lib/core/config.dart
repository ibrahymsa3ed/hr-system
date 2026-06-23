/// App configuration. Override the API base URL at build/run time with:
///   flutter run --dart-define=API_BASE_URL=http://localhost:8000/api
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://hr.130.110.111.198.nip.io/api',
  );
}
