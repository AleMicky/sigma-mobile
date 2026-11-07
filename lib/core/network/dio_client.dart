import 'package:dio/dio.dart';
import 'package:sigma_mobile/core/config/app_config.dart';
import 'package:sigma_mobile/features/auth/auth_service.dart';

class DioClient {
  DioClient._();

  static final Dio instance = _createDio();

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Sincroniza dinámicamente el baseUrl si el usuario lo cambia desde ajustes
    AppConfig.apiBaseUrlNotifier.addListener(() {
      dio.options.baseUrl = AppConfig.apiBaseUrl;
    });

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            options.baseUrl = AppConfig.apiBaseUrl;

            final token = await AuthService.instance.getAccessToken();

            if (token == null) {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.cancel,
                  error: 'No existe una sesión activa',
                ),
              );
            }

            options.headers['Authorization'] = 'Bearer $token';

            handler.next(options);
          } catch (error) {
            handler.reject(DioException(requestOptions: options, error: error));
          }
        },
      ),
    );

    return dio;
  }
}
