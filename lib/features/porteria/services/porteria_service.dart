import 'package:dio/dio.dart';
import 'package:sigma_mobile/core/network/dio_client.dart';
import 'package:sigma_mobile/features/porteria/models/porteria_models.dart';

class PorteriaService {
  PorteriaService._();

  static final PorteriaService instance = PorteriaService._();

  Dio get _dio => DioClient.instance;

  /// `GET /porteria/afuera`
  Future<List<RegistroPorteria>> listarAfuera() async {
    final response = await _dio.get('porteria/afuera');
    final data = _unwrapData(response.data);

    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => RegistroPorteria.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return const [];
  }

  /// `GET /porteria`
  Future<PorteriaPageResult> listar({
    int page = 0,
    int size = 20,
    String? search,
    String? empleadoId,
    String? activoId,
    String? areaId,
    EstadoRegistroPorteria? estado,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
      'sortBy': 'fechaHoraSalida',
      'direction': 'DESC',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (empleadoId != null && empleadoId.isNotEmpty) 'empleadoId': empleadoId,
      if (activoId != null && activoId.isNotEmpty) 'activoId': activoId,
      if (areaId != null && areaId.isNotEmpty) 'areaId': areaId,
      if (estado != null) 'estado': estado.value,
      if (fechaDesde != null)
        'fechaDesde': fechaDesde.toUtc().toIso8601String(),
      if (fechaHasta != null)
        'fechaHasta': fechaHasta.toUtc().toIso8601String(),
    };

    final response = await _dio.get('porteria', queryParameters: queryParams);
    final data = _unwrapData(response.data);

    if (data is Map) {
      return PorteriaPageResult.fromJson(Map<String, dynamic>.from(data));
    }

    return const PorteriaPageResult(
      content: [],
      page: 0,
      size: 20,
      totalElements: 0,
      totalPages: 0,
    );
  }

  /// `GET /porteria/{id}`
  Future<RegistroPorteria> obtenerPorId(String id) async {
    final response = await _dio.get('porteria/$id');
    final data = _unwrapMap(response.data);
    return RegistroPorteria.fromJson(data);
  }

  /// `POST /porteria/salidas`
  Future<RegistroPorteria> registrarSalida(
    RegistrarSalidaPorteriaInput input,
  ) async {
    final response = await _dio.post(
      'porteria/salidas',
      data: input.toJson(),
    );
    final data = _unwrapMap(response.data);
    return RegistroPorteria.fromJson(data);
  }

  /// `POST /porteria/{id}/llegada`
  Future<RegistroPorteria> registrarLlegada(
    String id,
    RegistrarLlegadaPorteriaInput input,
  ) async {
    final response = await _dio.post(
      'porteria/$id/llegada',
      data: input.toJson(),
    );
    final data = _unwrapMap(response.data);
    return RegistroPorteria.fromJson(data);
  }

  /// `POST /porteria/{id}/anular`
  Future<RegistroPorteria> anular(String id, {String? motivo}) async {
    final response = await _dio.post(
      'porteria/$id/anular',
      data: {
        if (motivo != null && motivo.trim().isNotEmpty) 'motivo': motivo.trim(),
      },
    );
    final data = _unwrapMap(response.data);
    return RegistroPorteria.fromJson(data);
  }

  /// `GET /empleados` (para selector de funcionario en el registro de salida)
  Future<List<FuncionarioOption>> buscarFuncionarios({
    String? query,
    int page = 0,
    int size = 25,
  }) async {
    final response = await _dio.get(
      'empleados',
      queryParameters: {
        'page': page,
        'size': size,
        'sortBy': 'codigo',
        'direction': 'ASC',
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      },
    );

    final data = _unwrapData(response.data);
    if (data is Map && data['content'] is List) {
      final list = data['content'] as List;
      return list
          .whereType<Map>()
          .map(
            (item) => FuncionarioOption.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }
    return const [];
  }

  /// `GET /activos` (para selector de activo catalogado en el registro de salida)
  Future<List<ActivoOption>> buscarActivos({
    String? query,
    int page = 0,
    int size = 25,
  }) async {
    final response = await _dio.get(
      'activos',
      queryParameters: {
        'page': page,
        'size': size,
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      },
    );

    final data = _unwrapData(response.data);
    if (data is Map && data['content'] is List) {
      final list = data['content'] as List;
      return list
          .whereType<Map>()
          .map(
            (item) => ActivoOption.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }
    return const [];
  }

  dynamic _unwrapData(dynamic body) {
    if (body is Map) {
      if (body['success'] == false) {
        final msg = body['message']?.toString() ?? 'La operación no fue exitosa';
        throw Exception(msg);
      }
      if (body.containsKey('data')) {
        return body['data'];
      }
    }
    return body;
  }

  Map<String, dynamic> _unwrapMap(dynamic body) {
    final data = _unwrapData(body);
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw const FormatException('Respuesta inválida del servidor');
  }

  static String extractErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final msg = data['message']?.toString();
        if (msg != null && msg.trim().isNotEmpty) {
          return msg.trim();
        }
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Tiempo de espera agotado al conectar con el servidor.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'No se pudo conectar al servidor SIGMA API.';
      }
      if (error.message != null && error.message!.trim().isNotEmpty) {
        return error.message!.trim();
      }
    }
    return error.toString().replaceFirst('Exception: ', '');
  }
}

