class ApiConfig {
  ApiConfig._();

  static const productionBaseUrl = 'https://school-app-1uep.onrender.com';
  static const stagingBaseUrl = 'https://school-backend-staging.onrender.com';
  static const releaseTarget = String.fromEnvironment('API_ENV');

  static String get releaseBaseUrl => resolveReleaseBaseUrl(releaseTarget);

  static String resolveReleaseBaseUrl(String target) {
    switch (target) {
      case 'production':
        return productionBaseUrl;
      case 'staging':
        return stagingBaseUrl;
      default:
        throw StateError(
          'Release builds require --dart-define=API_ENV=staging or production.',
        );
    }
  }
}
