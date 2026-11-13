import 'package:dio/dio.dart';
import 'package:sigma_mobile/core/network/dio_client.dart';
import 'package:sigma_mobile/features/porteria/models/porteria_models.dart';
import 'package:sigma_mobile/features/solicitud_vehicular/models/solicitud_vehicular_models.dart';

class SolicitudVehicularService {
  SolicitudVehicularService._();

  static final SolicitudVehicularService instance = SolicitudVehicularService._();

  Dio get _dio => DioClient.instance;

  /// `GET /solicitudes-vehiculares`
  Future<SolicitudVehicularPageResult> listar({
    int page = 0,
    int size = 20,
    String? search,
    String? estado,
    String? tipoId,
    String? solicitanteId,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
      'sortBy': 'createdAt',
      'direction': 'DESC',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (estado != null && estado.isNotEmpty) 'estado': estado,
      if (tipoId != null && tipoId.isNotEmpty) 'tipoSolicitudVehicularId': tipoId,
      if (solicitanteId != null && solicitanteId.isNotEmpty)
        'solicitanteId': solicitanteId,
    };

    final response = await _dio.get(
      'solicitudes-vehiculares',
      queryParameters: queryParams,
    );

    final data = _unwrapData(response.data);

    if (data is Map) {
      return SolicitudVehicularPageResult.fromJson(
        Map<String, dynamic>.from(data),
      );
    }

    return const SolicitudVehicularPageResult(
      content: [],
      page: 0,
      size: 20,
      totalElements: 0,
      totalPages: 0,
    );
  }

  /// `GET /solicitudes-vehiculares/{id}`
  Future<SolicitudVehicular> obtenerPorId(String id) async {
    final response = await _dio.get('solicitudes-vehiculares/$id');
    final data = _unwrapMap(response.data);
    return SolicitudVehicular.fromJson(data);
  }

  /// `POST /solicitudes-vehiculares`
  Future<SolicitudVehicular> crear(CrearSolicitudVehicularInput input) async {
    final response = await _dio.post(
      'solicitudes-vehiculares',
      data: input.toJson(),
    );
    final data = _unwrapMap(response.data);
    return SolicitudVehicular.fromJson(data);
  }

  /// `DELETE /solicitudes-vehiculares/{id}`
  Future<void> eliminar(String id) async {
    await _dio.delete('solicitudes-vehiculares/$id');
  }

  /// `GET /tipos-solicitud-vehicular`
  Future<List<TipoSolicitudVehicular>> listarTipos() async {
    try {
      final response = await _dio.get(
        'tipos-solicitud-vehicular',
        queryParameters: {'page': 0, 'size': 100},
      );
      final data = _unwrapData(response.data);

      if (data is Map && data['content'] is List) {
        return (data['content'] as List)
            .whereType<Map>()
            .map((item) => TipoSolicitudVehicular.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      } else if (data is List) {
        return data
            .whereType<Map>()
            .map((item) => TipoSolicitudVehicular.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (_) {
      // Retorna lista vacía si la petición falla
    }
    return const [];
  }

  /// `GET /conductores` o `GET /conductores/disponibles`
  Future<List<ConductorOption>> listarConductores({
    DateTime? fechaSalida,
    DateTime? fechaRetorno,
    String? query,
  }) async {
    // 1. Si se tienen fechas válidas, consultar disponibilidad primero
    if (fechaSalida != null && fechaRetorno != null && fechaRetorno.isAfter(fechaSalida)) {
      try {
        final response = await _dio.get(
          'conductores/disponibles',
          queryParameters: {
            'fechaSalida': fechaSalida.toUtc().toIso8601String(),
            'fechaRetorno': fechaRetorno.toUtc().toIso8601String(),
          },
        );
        final data = _unwrapData(response.data);
        if (data is List && data.isNotEmpty) {
          final list = data
              .whereType<Map>()
              .map((item) => ConductorOption.fromJson(Map<String, dynamic>.from(item)))
              .toList();
          if (query != null && query.trim().isNotEmpty) {
            final q = query.trim().toLowerCase();
            return list.where((c) {
              return c.nombreCompleto.toLowerCase().contains(q) ||
                  (c.codigo != null && c.codigo!.toLowerCase().contains(q)) ||
                  (c.numeroLicencia != null && c.numeroLicencia!.toLowerCase().contains(q));
            }).toList();
          }
          return list;
        }
      } catch (_) {
        // Fallback a catálogo general si disponibles no está disponible o falla
      }
    }

    // 2. Catálogo general de conductores activos
    try {
      final response = await _dio.get(
        'conductores',
        queryParameters: {
          'page': 0,
          'size': 100,
          'activo': true,
          if (query != null && query.trim().isNotEmpty) 'search': query.trim(),
        },
      );
      final data = _unwrapData(response.data);
      List? items;
      if (data is Map && data['content'] is List) {
        items = data['content'] as List;
      } else if (data is List) {
        items = data;
      }
      if (items != null && items.isNotEmpty) {
        return items
            .whereType<Map>()
            .map((item) => ConductorOption.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (_) {}

    // 3. Fallback: listar desde empleados
    try {
      final empleados = await buscarEmpleados(query: query, size: 50);
      if (empleados.isNotEmpty) {
        return empleados.map((e) => ConductorOption.fromFuncionario(e)).toList();
      }
    } catch (_) {}

    return const [];
  }

  /// `GET /empleados`
  Future<List<FuncionarioOption>> buscarEmpleados({
    String? query,
    int page = 0,
    int size = 30,
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

