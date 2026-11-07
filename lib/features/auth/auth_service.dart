import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sigma_mobile/core/config/app_config.dart';

class AuthService extends ChangeNotifier {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final Dio _http = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ),
  );

  bool _isAuthenticated = false;
  bool _hasCompletedOnboarding = false;
  Map<String, dynamic>? _user;
  DateTime? _expiresAt;
  Future<String?>? _refreshing;

  bool get isAuthenticated => _isAuthenticated;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  Map<String, dynamic>? get user => _user;

  String _onboardingKey() {
    final identifier =
        _user?['username']?.toString().trim() ??
        _user?['id']?.toString().trim() ??
        'default';
    return 'sigma_welcome_completed_$identifier';
  }

  Future<void> _loadOnboardingState() async {
    final value = await _storage.read(key: _onboardingKey());
    _hasCompletedOnboarding = value == 'true';
  }

  /// Marca como completada la bienvenida inicial del usuario actual.
  Future<void> completeOnboarding() async {
    await _storage.write(key: _onboardingKey(), value: 'true');
    _hasCompletedOnboarding = true;
    notifyListeners();
  }

  /// Permite volver a mostrar la pantalla de bienvenida si se requiere.
  Future<void> resetOnboarding() async {
    await _storage.delete(key: _onboardingKey());
    _hasCompletedOnboarding = false;
    notifyListeners();
  }

  Future<void> initialize() async {
    _http.options.baseUrl = AppConfig.apiBaseUrl;
    AppConfig.apiBaseUrlNotifier.addListener(_syncBaseUrl);

    try {
      final token = await getAccessToken();

      if (token == null) {
        _isAuthenticated = false;
        notifyListeners();
        return;
      }

      // Comprueba la sesión contra Spring Boot.
      await loadUser();
    } catch (_) {
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  void _syncBaseUrl() {
    _http.options.baseUrl = AppConfig.apiBaseUrl;
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    _http.options.baseUrl = AppConfig.apiBaseUrl;
    final response = await _http.post(
      AppConfig.loginPath,
      data: {'username': username, 'password': password},
    );

    final data = _responseData(response.data);

    await _saveSession(data);

    final returnedUser = data['user'];

    if (returnedUser is Map) {
      _user = Map<String, dynamic>.from(returnedUser);
      await _loadOnboardingState();
    } else {
      await loadUser();
    }

    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    final accessToken = data['accessToken'];
    final refreshToken = data['refreshToken'];
    final expiresIn = data['expiresIn'];

    if (accessToken is! String ||
        accessToken.isEmpty ||
        refreshToken is! String ||
        refreshToken.isEmpty ||
        expiresIn is! num) {
      throw const FormatException('Respuesta de autenticación inválida');
    }

    _expiresAt = DateTime.now().toUtc().add(
      Duration(seconds: expiresIn.toInt()),
    );

    await _storage.write(key: 'access_token', value: accessToken);

    await _storage.write(key: 'refresh_token', value: refreshToken);

    await _storage.write(
      key: 'expires_at',
      value: _expiresAt!.toIso8601String(),
    );
  }

  Map<String, dynamic> _responseData(dynamic body) {
    if (body is! Map || body['success'] != true) {
      throw const FormatException('La API no confirmó la operación');
    }

    final data = body['data'];

    if (data is! Map) {
      throw const FormatException('La API no devolvió datos válidos');
    }

    return Map<String, dynamic>.from(data);
  }

  Future<String?> getAccessToken() async {
    final token = await _storage.read(key: 'access_token');

    if (token == null || token.isEmpty) {
      return null;
    }

    final storedExpiration = await _storage.read(key: 'expires_at');

    _expiresAt ??= storedExpiration == null
        ? null
        : DateTime.tryParse(storedExpiration);

    if (_expiresAt != null &&
        DateTime.now().toUtc().isBefore(
          _expiresAt!.subtract(const Duration(seconds: 30)),
        )) {
      return token;
    }

    return refreshToken();
  }

  Future<String?> refreshToken() {
    // Evita renovar varias veces simultáneamente.
    return _refreshing ??= _performRefresh().whenComplete(() {
      _refreshing = null;
    });
  }

  Future<String?> _performRefresh() async {
    final storedRefreshToken = await _storage.read(key: 'refresh_token');

    if (storedRefreshToken == null || storedRefreshToken.isEmpty) {
      return null;
    }

    final response = await _http.post(
      AppConfig.refreshPath,
      data: {'refreshToken': storedRefreshToken},
    );

    final data = _responseData(response.data);

    // Spring Boot devuelve un nuevo par de tokens.
    await _saveSession(data);

    final returnedUser = data['user'];

    if (returnedUser is Map) {
      _user = Map<String, dynamic>.from(returnedUser);
    }

    return data['accessToken'] as String;
  }

  Future<void> loadUser() async {
    final token = await getAccessToken();

    if (token == null) {
      throw StateError('No existe una sesión activa');
    }

    final response = await _http.get(
      AppConfig.mePath,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    _user = _responseData(response.data);
    await _loadOnboardingState();
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> logout() async {
    final refreshToken = await _storage.read(key: 'refresh_token');

    try {
      if (refreshToken != null) {
        final token = await getAccessToken();

        await _http.post(
          AppConfig.logoutPath,
          data: {'refreshToken': refreshToken},
          options: Options(
            headers: {if (token != null) 'Authorization': 'Bearer $token'},
          ),
        );
      }
    } finally {
      // Limpieza local incluso si no se puede
      // contactar con el servidor.
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
      await _storage.delete(key: 'expires_at');

      _expiresAt = null;
      _user = null;
      _isAuthenticated = false;
      _hasCompletedOnboarding = false;

      notifyListeners();
    }
  }
}
