import 'package:dio/dio.dart';
import 'package:sigma_mobile/core/network/dio_client.dart';
import 'package:sigma_mobile/features/porteria/models/porteria_models.dart';
import 'package:sigma_mobile/features/salida_vehicular/models/salida_vehicular_models.dart';

class SalidaVehicularService {
  SalidaVehicularService._();

  static final SalidaVehicularService instance = SalidaVehicularService._();

  Dio get _dio => DioClient.instance;

  /// `GET /salidas-vehiculares`
  Future<SalidaVehicularPageResult> listar({
    int page = 0,
    int size = 20,
    String? search,
    String? estado,
    String? activoId,
    String? empleadoId,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
      'sortBy': 'createdAt',
      'direction': 'DESC',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (estado != null && estado.isNotEmpty) 'estado': estado,
      if (activoId != null && activoId.isNotEmpty) 'activoId': activoId,
      if (empleadoId != null && empleadoId.isNotEmpty) 'empleadoId': empleadoId,
    };

    final response = await _dio.get(
      'salidas-vehiculares',
      queryParameters: queryParams,
    );

    final data = _unwrapData(response.data);

    if (data is Map) {
      return SalidaVehicularPageResult.fromJson(
        Map<String, dynamic>.from(data),
      );
    }

    return const SalidaVehicularPageResult(
      content: [],
      page: 0,
      size: 20,
      totalElements: 0,
      totalPages: 0,
    );
  }

  /// `GET /salidas-vehiculares/{id}`
  Future<SalidaVehicular> obtenerPorId(String id) async {
    final response = await _dio.get('salidas-vehiculares/$id');
    final data = _unwrapMap(response.data);
    return SalidaVehicular.fromJson(data);
  }

  /// `POST /salidas-vehiculares`
  Future<SalidaVehicular> registrar(CrearSalidaVehicularInput input) async {
    final response = await _dio.post(
      'salidas-vehiculares',
      data: input.toJson(),
    );
    final data = _unwrapMap(response.data);
    return SalidaVehicular.fromJson(data);
  }

  /// `POST /salidas-vehiculares/{id}/cancelar`
  Future<SalidaVehicular> cancelar(String id, {String? motivo}) async {
    final response = await _dio.post(
      'salidas-vehiculares/$id/cancelar',
      data: {
        if (motivo != null && motivo.trim().isNotEmpty)
          'motivo': motivo.trim(),
      },
    );
    final data = _unwrapMap(response.data);
    return SalidaVehicular.fromJson(data);
  }

  /// `GET /salidas-vehiculares/{id}/acciones`
  Future<WorkflowTaskActions?> obtenerAcciones(String id) async {
    try {
      final response = await _dio.get('salidas-vehiculares/$id/acciones');
      final data = _unwrapData(response.data);
      if (data is Map) {
        return WorkflowTaskActions.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (_) {
      // Flowable actions might not be initialized or available
    }
    return null;
  }

  /// `POST /salidas-vehiculares/{id}/acciones/{accionId}/ejecutar`
  Future<SalidaVehicular> ejecutarAccion(
    String id,
    String accionId,
    EjecutarAccionSalidaInput input,
  ) async {
    final response = await _dio.post(
      'salidas-vehiculares/$id/acciones/${Uri.encodeComponent(accionId)}/ejecutar',
      data: input.toJson(),
    );
    final data = _unwrapMap(response.data);
    return SalidaVehicular.fromJson(data);
  }

  /// `GET /salidas-vehiculares/{id}/bitacoras`
  Future<List<BitacoraVehicular>> listarBitacoras(String id) async {
    try {
      final response = await _dio.get('salidas-vehiculares/$id/bitacoras');
      final data = _unwrapData(response.data);
      if (data is List) {
        return data
            .whereType<Map>()
            .map((b) => BitacoraVehicular.fromJson(Map<String, dynamic>.from(b)))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// `POST /salidas-vehiculares/{id}/bitacoras`
  Future<BitacoraVehicular> registrarBitacora(
    String id,
    RegistrarBitacoraInput input,
  ) async {
    final response = await _dio.post(
      'salidas-vehiculares/$id/bitacoras',
      data: input.toJson(),
    );
    final data = _unwrapMap(response.data);
    return BitacoraVehicular.fromJson(data);
  }

  /// `GET /activos`
  Future<List<ActivoOption>> listarVehiculos({String? query}) async {
    try {
      final response = await _dio.get(
        'activos',
        queryParameters: {
          'page': 0,
          'size': 50,
          'sortBy': 'codigo',
          'direction': 'ASC',
          if (query != null && query.trim().isNotEmpty) 'search': query.trim(),
        },
      );
      final data = _unwrapData(response.data);
      List? items;
      if (data is Map) {
        items = data['content'] as List?;
      } else if (data is List) {
        items = data;
      }
      if (items != null) {
        return items
            .whereType<Map>()
            .map((e) => ActivoOption.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// `GET /empleados`
  Future<List<FuncionarioOption>> listarEmpleados({String? query}) async {
    try {
      final response = await _dio.get(
        'empleados',
        queryParameters: {
          'page': 0,
          'size': 50,
          'sortBy': 'persona.nombres',
          'direction': 'ASC',
          if (query != null && query.trim().isNotEmpty) 'search': query.trim(),
        },
      );
      final data = _unwrapData(response.data);
      List? items;
      if (data is Map) {
        items = data['content'] as List?;
      } else if (data is List) {
        items = data;
      }
      if (items != null) {
        return items
            .whereType<Map>()
            .map((e) => FuncionarioOption.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  dynamic _unwrapData(dynamic raw) {
    if (raw is Map) {
      if (raw.containsKey('data')) return raw['data'];
      if (raw.containsKey('content')) return raw;
    }
    return raw;
  }

  Map<String, dynamic> _unwrapMap(dynamic raw) {
    final unwrap = _unwrapData(raw);
    if (unwrap is Map) {
      return Map<String, dynamic>.from(unwrap);
    }
    return {};
  }
}

