import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppConfig {
  AppConfig._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _customApiUrlKey = 'sigma_custom_api_base_url';

  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  /// URL por defecto compilada o pasada por `--dart-define=API_BASE_URL=...`
  static const String defaultApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://157.173.99.216:8085/api/v1/',
  );

  static String _currentApiBaseUrl = defaultApiBaseUrl;

  /// Notificador para escuchar cambios en la URL de la API en tiempo real.
  static final ValueNotifier<String> apiBaseUrlNotifier = ValueNotifier<String>(
    defaultApiBaseUrl,
  );

  /// URL activa actualmente en toda la aplicación.
  static String get apiBaseUrl => _currentApiBaseUrl;

  /// Indica si se está usando una URL personalizada distinta a la predeterminada.
  static bool get isCustomUrl => _currentApiBaseUrl != defaultApiBaseUrl;

  static const String loginPath = 'auth/login';
  static const String mePath = 'auth/me';
  static const String refreshPath = 'auth/refresh';
  static const String logoutPath = 'auth/logout';
  static const String healthPath = 'health';

  static const String keycloakRealm = 'sigma';
  static bool get isProduction => environment == 'prod';

  /// Carga la URL guardada en el dispositivo al iniciar la app.
  static Future<void> initialize() async {
    try {
      final savedUrl = await _storage.read(key: _customApiUrlKey);
      if (savedUrl != null && savedUrl.trim().isNotEmpty) {
        _currentApiBaseUrl = normalizeUrl(savedUrl);
        apiBaseUrlNotifier.value = _currentApiBaseUrl;
      }
    } catch (_) {
      _currentApiBaseUrl = defaultApiBaseUrl;
    }
  }

  /// Guarda y aplica dinámicamente una nueva URL base para la API.
  static Future<void> setApiBaseUrl(String url) async {
    final normalized = normalizeUrl(url);
    _currentApiBaseUrl = normalized;
    apiBaseUrlNotifier.value = normalized;
    await _storage.write(key: _customApiUrlKey, value: normalized);
  }

  /// Restaura la URL base por defecto y elimina la configuración personalizada.
  static Future<void> resetApiBaseUrl() async {
    _currentApiBaseUrl = defaultApiBaseUrl;
    apiBaseUrlNotifier.value = defaultApiBaseUrl;
    await _storage.delete(key: _customApiUrlKey);
  }

  /// Asegura que la URL tenga formato válido y termine con `/`.
  static String normalizeUrl(String rawUrl) {
    var trimmed = rawUrl.trim();
    if (!trimmed.endsWith('/')) {
      trimmed = '$trimmed/';
    }
    return trimmed;
  }
}
