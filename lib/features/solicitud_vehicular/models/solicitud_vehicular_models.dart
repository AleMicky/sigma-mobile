import 'package:flutter/material.dart';
import 'package:sigma_mobile/features/porteria/models/porteria_models.dart';

enum EstadoSolicitudVehicular {
  borrador('BORRADOR', 'Borrador', Color(0xFF64748B), Icons.edit_note_rounded),
  pendiente('PENDIENTE', 'Pendiente', Color(0xFFD97706), Icons.hourglass_top_rounded),
  aprobada('APROBADA', 'Aprobada', Color(0xFF2563EB), Icons.check_circle_outline_rounded),
  asignada('ASIGNADA', 'Asignada', Color(0xFF0284C7), Icons.directions_car_rounded),
  enCurso('EN_CURSO', 'En curso', Color(0xFF059669), Icons.navigation_rounded),
  finalizada('FINALIZADA', 'Finalizada', Color(0xFF10B981), Icons.task_alt_rounded),
  rechazada('RECHAZADA', 'Rechazada', Color(0xFFDC2626), Icons.cancel_outlined),
  anulada('ANULADA', 'Anulada', Color(0xFF94A3B8), Icons.block_rounded);

  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const EstadoSolicitudVehicular(this.value, this.label, this.color, this.icon);

  static EstadoSolicitudVehicular fromString(String? raw) {
    final norm = raw?.toUpperCase().trim() ?? '';
    switch (norm) {
      case 'BORRADOR':
        return EstadoSolicitudVehicular.borrador;
      case 'PENDIENTE':
        return EstadoSolicitudVehicular.pendiente;
      case 'APROBADA':
      case 'APROBADO':
        return EstadoSolicitudVehicular.aprobada;
      case 'ASIGNADA':
      case 'ASIGNADO':
        return EstadoSolicitudVehicular.asignada;
      case 'EN_CURSO':
        return EstadoSolicitudVehicular.enCurso;
      case 'FINALIZADA':
      case 'FINALIZADO':
        return EstadoSolicitudVehicular.finalizada;
      case 'RECHAZADA':
      case 'RECHAZADO':
        return EstadoSolicitudVehicular.rechazada;
      case 'ANULADA':
      case 'ANULADO':
        return EstadoSolicitudVehicular.anulada;
      default:
        return EstadoSolicitudVehicular.pendiente;
    }
  }
}

class TipoSolicitudVehicular {
  final String id;
  final String codigo;
  final String nombre;
  final String? descripcion;
  final int diasAnticipacion;
  final bool requiereRespaldo;
  final bool requiereJustificacion;

  const TipoSolicitudVehicular({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    this.diasAnticipacion = 0,
    this.requiereRespaldo = false,
    this.requiereJustificacion = false,
  });

  bool get esEmergencia =>
      codigo.toUpperCase() == 'EMERGENCIA' ||
      diasAnticipacion == 0 ||
      nombre.toUpperCase().contains('EMERGENCIA');

  factory TipoSolicitudVehicular.fromJson(Map<String, dynamic> json) {
    return TipoSolicitudVehicular(
      id: json['id']?.toString() ?? '',
      codigo: json['codigo']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      diasAnticipacion: (json['diasAnticipacion'] as num?)?.toInt() ?? 0,
      requiereRespaldo: json['requiereRespaldo'] == true,
      requiereJustificacion: json['requiereJustificacion'] == true,
    );
  }
}

class SolicitanteVehicularInfo {
  final String id;
  final String codigo;
  final String nombreCompleto;
  final String? cargo;
  final String? area;

  const SolicitanteVehicularInfo({
    required this.id,
    required this.codigo,
    required this.nombreCompleto,
    this.cargo,
    this.area,
  });

  String get subtitulo {
    final parts = [
      if (cargo != null && cargo!.trim().isNotEmpty) cargo!.trim(),
      if (area != null && area!.trim().isNotEmpty) area!.trim(),
    ];
    return parts.join(' · ');
  }

  factory SolicitanteVehicularInfo.fromJson(Map<String, dynamic> json) {
    return SolicitanteVehicularInfo(
      id: json['id']?.toString() ?? '',
      codigo: json['codigo']?.toString() ?? '',
      nombreCompleto: json['nombreCompleto']?.toString() ?? 'Funcionario',
      cargo: json['cargo']?.toString(),
      area: json['area']?.toString(),
    );
  }
}

class ConductorAsignadoInfo {
  final String id;
  final String? empleadoId;
  final String? nombreCompleto;
  final String? numeroLicencia;
  final String? categoriaLicencia;

  const ConductorAsignadoInfo({
    required this.id,
    this.empleadoId,
    this.nombreCompleto,
    this.numeroLicencia,
    this.categoriaLicencia,
  });

  factory ConductorAsignadoInfo.fromJson(Map<String, dynamic> json) {
    return ConductorAsignadoInfo(
      id: json['id']?.toString() ?? '',
      empleadoId: json['empleadoId']?.toString(),
      nombreCompleto: json['nombreCompleto']?.toString(),
      numeroLicencia: json['numeroLicencia']?.toString(),
      categoriaLicencia: json['categoriaLicencia']?.toString(),
    );
  }
}

class SolicitudVehicular {
  final String id;
  final String numero;
  final String tipoSolicitudVehicularId;
  final TipoSolicitudVehicular? tipoSolicitud;
  final String solicitanteId;
  final SolicitanteVehicularInfo? solicitante;
  final String motivo;
  final String? justificacion;
  final String destino;
  final DateTime fechaSalida;
  final DateTime fechaRetornoEstimada;
  final int cantidadPasajeros;
  final String? observacion;
  final EstadoSolicitudVehicular estado;
  final String rawEstado;
  final String? processInstanceId;
  final String? conductorAsignadoId;
  final ConductorAsignadoInfo? conductorAsignado;
  final String? activoId;
  final String? activoPlaca;
  final String? activoModelo;
  final DateTime? createdAt;

  const SolicitudVehicular({
    required this.id,
    required this.numero,
    required this.tipoSolicitudVehicularId,
    this.tipoSolicitud,
    required this.solicitanteId,
    this.solicitante,
    required this.motivo,
    this.justificacion,
    required this.destino,
    required this.fechaSalida,
    required this.fechaRetornoEstimada,
    required this.cantidadPasajeros,
    this.observacion,
    required this.estado,
    required this.rawEstado,
    this.processInstanceId,
    this.conductorAsignadoId,
    this.conductorAsignado,
    this.activoId,
    this.activoPlaca,
    this.activoModelo,
    this.createdAt,
  });

  bool get esEditable =>
      estado == EstadoSolicitudVehicular.borrador ||
      estado == EstadoSolicitudVehicular.pendiente;

  bool get puedeEliminar =>
      estado == EstadoSolicitudVehicular.borrador ||
      estado == EstadoSolicitudVehicular.pendiente;

  String get duracionCalculada {
    final diff = fechaRetornoEstimada.difference(fechaSalida);
    if (diff.isNegative) return 'Inconsistente';
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min';
    }
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final parts = <String>[];
    if (days > 0) parts.add('$days ${days == 1 ? "día" : "días"}');
    if (hours > 0) parts.add('$hours ${hours == 1 ? "hr" : "hrs"}');
    return parts.isNotEmpty ? parts.join(', ') : '${diff.inMinutes} min';
  }

  factory SolicitudVehicular.fromJson(Map<String, dynamic> json) {
    final tipoRaw = json['tipoSolicitudVehicular'];
    final solicitanteRaw = json['solicitante'];
    final conductorRaw = json['conductorAsignado'];
    final auditoriaRaw = json['auditoria'];

    final rawEstadoStr = json['estado']?.toString() ?? 'PENDIENTE';

    DateTime parseDate(dynamic value) {
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed.toLocal();
      }
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed.toLocal();
      }
      return null;
    }

    return SolicitudVehicular(
      id: json['id']?.toString() ?? '',
      numero: json['numero']?.toString() ?? '',
      tipoSolicitudVehicularId: json['tipoSolicitudVehicularId']?.toString() ?? '',
      tipoSolicitud: tipoRaw is Map
          ? TipoSolicitudVehicular.fromJson(Map<String, dynamic>.from(tipoRaw))
          : null,
      solicitanteId: json['solicitanteId']?.toString() ?? '',
      solicitante: solicitanteRaw is Map
          ? SolicitanteVehicularInfo.fromJson(Map<String, dynamic>.from(solicitanteRaw))
          : null,
      motivo: json['motivo']?.toString() ?? '',
      justificacion: json['justificacion']?.toString(),
      destino: json['destino']?.toString() ?? '',
      fechaSalida: parseDate(json['fechaSalida']),
      fechaRetornoEstimada: parseDate(json['fechaRetornoEstimada']),
      cantidadPasajeros: (json['cantidadPasajeros'] as num?)?.toInt() ?? 1,
      observacion: json['observacion']?.toString(),
      estado: EstadoSolicitudVehicular.fromString(rawEstadoStr),
      rawEstado: rawEstadoStr,
      processInstanceId: json['processInstanceId']?.toString(),
      conductorAsignadoId: json['conductorAsignadoId']?.toString(),
      conductorAsignado: conductorRaw is Map
          ? ConductorAsignadoInfo.fromJson(Map<String, dynamic>.from(conductorRaw))
          : null,
      activoId: json['activoId']?.toString(),
      activoPlaca: json['activoPlaca']?.toString(),
      activoModelo: json['activoModelo']?.toString(),
      createdAt: auditoriaRaw is Map ? parseNullableDate(auditoriaRaw['createdAt']) : null,
    );
  }
}

class SolicitudVehicularPageResult {
  final List<SolicitudVehicular> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool first;
  final bool last;

  const SolicitudVehicularPageResult({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    this.first = true,
    this.last = true,
  });

  factory SolicitudVehicularPageResult.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'];
    final items = rawContent is List
        ? rawContent
            .whereType<Map>()
            .map((item) => SolicitudVehicular.fromJson(Map<String, dynamic>.from(item)))
            .toList()
        : <SolicitudVehicular>[];

    return SolicitudVehicularPageResult(
      content: items,
      page: (json['page'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 20,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? items.length,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      first: json['first'] == true,
      last: json['last'] == true,
    );
  }
}

class ConductorOption {
  final String id;
  final String? empleadoId;
  final String nombreCompleto;
  final String? codigo;
  final String? cargo;
  final String? area;
  final String? numeroLicencia;
  final String? categoriaLicencia;
  final String? urlImagen;

  const ConductorOption({
    required this.id,
    this.empleadoId,
    required this.nombreCompleto,
    this.codigo,
    this.cargo,
    this.area,
    this.numeroLicencia,
    this.categoriaLicencia,
    this.urlImagen,
  });

  factory ConductorOption.fromJson(Map<String, dynamic> json) {
    final emp = json['empleado'] is Map ? json['empleado'] as Map : null;
    final nombre = json['nombreCompleto']?.toString() ??
        emp?['nombreCompleto']?.toString() ??
        'Conductor';
    final codigo = emp?['codigo']?.toString() ?? json['codigo']?.toString();
    final cargo = emp?['cargo']?.toString() ?? json['cargo']?.toString();
    final area = emp?['area']?.toString() ?? json['area']?.toString();

    String? numLic = json['numeroLicencia']?.toString();
    String? catLic = json['categoriaLicencia']?.toString();

    if (json['licencias'] is List && (json['licencias'] as List).isNotEmpty) {
      final licList = json['licencias'] as List;
      final vigente = licList.firstWhere(
        (l) => l is Map && l['estado'] == 'VIGENTE',
        orElse: () => licList.first,
      );
      if (vigente is Map) {
        numLic ??= vigente['numeroLicencia']?.toString();
        catLic ??= vigente['categoriaLicencia']?.toString();
      }
    }

    return ConductorOption(
      id: json['id']?.toString() ?? '',
      empleadoId: json['empleadoId']?.toString() ?? emp?['id']?.toString(),
      nombreCompleto: nombre,
      codigo: codigo,
      cargo: cargo,
      area: area,
      numeroLicencia: numLic,
      categoriaLicencia: catLic,
      urlImagen: json['urlImagen']?.toString(),
    );
  }

  factory ConductorOption.fromFuncionario(FuncionarioOption f) {
    return ConductorOption(
      id: f.id,
      nombreCompleto: f.nombreCompleto,
      codigo: f.codigo,
      cargo: f.cargo,
      area: f.area,
    );
  }

  String get subtitulo {
    final parts = [
      if (categoriaLicencia != null && categoriaLicencia!.trim().isNotEmpty)
        'Cat. $categoriaLicencia',
      if (numeroLicencia != null && numeroLicencia!.trim().isNotEmpty)
        'Lic. $numeroLicencia',
      if (cargo != null && cargo!.trim().isNotEmpty) cargo!.trim(),
      if (codigo != null && codigo!.trim().isNotEmpty) codigo!.trim(),
    ];
    return parts.join(' · ');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConductorOption && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class CrearSolicitudVehicularInput {
  final String tipoSolicitudVehicularId;
  final String solicitanteId;
  final String? conductorAsignadoId;
  final String motivo;
  final String? justificacion;
  final String destino;
  final DateTime fechaSalida;
  final DateTime fechaRetornoEstimada;
  final int cantidadPasajeros;
  final String? observacion;

  const CrearSolicitudVehicularInput({
    required this.tipoSolicitudVehicularId,
    required this.solicitanteId,
    this.conductorAsignadoId,
    required this.motivo,
    this.justificacion,
    required this.destino,
    required this.fechaSalida,
    required this.fechaRetornoEstimada,
    required this.cantidadPasajeros,
    this.observacion,
  });

  Map<String, dynamic> toJson() {
    return {
      'tipoSolicitudVehicularId': tipoSolicitudVehicularId,
      'solicitanteId': solicitanteId,
      if (conductorAsignadoId != null && conductorAsignadoId!.trim().isNotEmpty)
        'conductorAsignadoId': conductorAsignadoId!.trim(),
      'motivo': motivo.trim(),
      if (justificacion != null && justificacion!.trim().isNotEmpty)
        'justificacion': justificacion!.trim(),
      'destino': destino.trim(),
      'fechaSalida': fechaSalida.toUtc().toIso8601String(),
      'fechaRetornoEstimada': fechaRetornoEstimada.toUtc().toIso8601String(),
      'cantidadPasajeros': cantidadPasajeros,
      if (observacion != null && observacion!.trim().isNotEmpty)
        'observacion': observacion!.trim(),
      'estado': 'PENDIENTE',
    };
  }
}

