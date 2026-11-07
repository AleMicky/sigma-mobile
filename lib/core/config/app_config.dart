class AppConfig {
  AppConfig._();

  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://157.173.99.216:8085/api/v1/',
  );

  static const String loginPath = 'auth/login';
  static const String mePath = 'auth/me';
  static const String refreshPath = 'auth/refresh';
  static const String logoutPath = 'auth/logout';

  static const String keycloakRealm = 'sigma';
  static bool get isProduction => environment == 'prod';
}
