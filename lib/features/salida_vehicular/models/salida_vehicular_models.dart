import 'package:flutter/material.dart';

class SalidaVehicular {
  final String id;
  final String numero;
  final String activoId;
  final String? activoCodigo;
  final String? activoDescripcion;
  final String? placa;
  final String? marca;
  final String? modelo;
  final String empleadoId;
  final String? empleadoCodigo;
  final String? empleadoNombre;
  final DateTime fecha;
  final String descripcionActividad;
  final String? observaciones;
  final String estado;
  final String? processInstanceId;
  final List<SalidaVehicularEvento> eventos;
  final List<BitacoraVehicular> bitacoras;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SalidaVehicular({
    required this.id,
    required this.numero,
    required this.activoId,
    this.activoCodigo,
    this.activoDescripcion,
    this.placa,
    this.marca,
    this.modelo,
    required this.empleadoId,
    this.empleadoCodigo,
    this.empleadoNombre,
    required this.fecha,
    required this.descripcionActividad,
    this.observaciones,
    required this.estado,
    this.processInstanceId,
    this.eventos = const [],
    this.bitacoras = const [],
    this.createdAt,
    this.updatedAt,
  });

  String get displayVehiculo {
    final mm = '${marca ?? ''} ${modelo ?? ''}'.trim();
    if (mm.isNotEmpty) return mm;
    if (activoDescripcion != null && activoDescripcion!.trim().isNotEmpty) {
      final clean = activoDescripcion!
          .replaceAll(RegExp(r'PLACA.*$', caseSensitive: false), '')
          .trim();
      if (clean.isNotEmpty) return clean;
    }
    return activoCodigo ?? 'Vehículo';
  }

  String get displayPlaca {
    if (placa != null && placa!.trim().isNotEmpty) {
      return placa!.trim().toUpperCase();
    }
    final match = RegExp(
      r'PLACA[:\s#-]+([A-Z0-9]+)',
      caseSensitive: false,
    ).firstMatch(activoDescripcion ?? '');
    if (match != null && match.group(1) != null) {
      return match.group(1)!.trim().toUpperCase();
    }
    return activoCodigo ?? '-';
  }

  String get displayConductor {
    if (empleadoNombre != null && empleadoNombre!.trim().isNotEmpty) {
      return empleadoNombre!.trim();
    }
    return empleadoCodigo ?? 'Conductor';
  }

  bool get isEnRuta {
    final e = estado.toUpperCase();
    return e.contains('SALIDA') ||
        e.contains('REGISTRAD') ||
        e.contains('INICIAD') ||
        e.contains('TRANSIT');
  }

  bool get isFinalizada {
    final e = estado.toUpperCase();
    return e.contains('LLEGAD') ||
        e.contains('FINALIZ') ||
        e.contains('COMPLET');
  }

  bool get isCancelada {
    final e = estado.toUpperCase();
    return e.contains('CANCEL') || e.contains('ANULAD');
  }

  Color get estadoColor {
    if (isCancelada) return Colors.red.shade700;
    if (isFinalizada) return const Color(0xFF0F766E); // Teal
    if (isEnRuta) return const Color(0xFF0284C7); // Sky blue
    return Colors.blueGrey;
  }

  String get estadoLabel {
    if (isCancelada) return 'CANCELADA';
    if (isFinalizada) return 'LLEGADA / FINALIZADA';
    if (isEnRuta) return 'EN RUTA (SALIDA)';
    return estado;
  }

  SalidaVehicularEvento? get eventoSalida {
    for (final ev in eventos) {
      if ((ev.tipoEvento).toUpperCase().contains('SALIDA')) return ev;
    }
    return eventos.isNotEmpty ? eventos.first : null;
  }

  SalidaVehicularEvento? get eventoLlegada {
    for (final ev in eventos) {
      if ((ev.tipoEvento).toUpperCase().contains('LLEGAD')) return ev;
    }
    return null;
  }

  double? get kilometrajeInicial => eventoSalida?.kilometraje;
  double? get kilometrajeFinal => eventoLlegada?.kilometraje;

  double? get recorridoKm {
    if (kilometrajeInicial != null && kilometrajeFinal != null) {
      final diff = kilometrajeFinal! - kilometrajeInicial!;
      return diff >= 0 ? diff : null;
    }
    return null;
  }

  factory SalidaVehicular.fromJson(Map<String, dynamic> json) {
    final rawEventos = json['eventos'];
    final eventosList = rawEventos is List
        ? rawEventos
            .whereType<Map>()
            .map(
              (e) => SalidaVehicularEvento.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList()
        : <SalidaVehicularEvento>[];

    final rawBitacoras = json['bitacoras'];
    final bitacorasList = rawBitacoras is List
        ? rawBitacoras
            .whereType<Map>()
            .map(
              (b) => BitacoraVehicular.fromJson(
                Map<String, dynamic>.from(b),
              ),
            )
            .toList()
        : <BitacoraVehicular>[];

    DateTime parsedFecha = DateTime.now();
    final rawFecha = json['fecha']?.toString();
    if (rawFecha != null) {
      parsedFecha = DateTime.tryParse(rawFecha) ?? DateTime.now();
    }

    return SalidaVehicular(
      id: json['id']?.toString() ?? '',
      numero: json['numero']?.toString() ?? '',
      activoId: json['activoId']?.toString() ?? '',
      activoCodigo: json['activoCodigo']?.toString(),
      activoDescripcion: json['activoDescripcion']?.toString(),
      placa: json['placa']?.toString(),
      marca: json['marca']?.toString(),
      modelo: json['modelo']?.toString(),
      empleadoId: json['empleadoId']?.toString() ?? '',
      empleadoCodigo: json['empleadoCodigo']?.toString(),
      empleadoNombre: json['empleadoNombre']?.toString(),
      fecha: parsedFecha,
      descripcionActividad: json['descripcionActividad']?.toString() ?? '',
      observaciones: json['observaciones']?.toString(),
      estado: json['estado']?.toString() ?? 'SALIDA',
      processInstanceId: json['processInstanceId']?.toString(),
      eventos: eventosList,
      bitacoras: bitacorasList,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}

class SalidaVehicularEvento {
  final String id;
  final String salidaVehicularId;
  final String? empleadoId;
  final String? empleadoNombre;
  final String tipoEvento;
  final DateTime fechaHora;
  final double? kilometraje;
  final double? latitud;
  final double? longitud;
  final String? observacion;

  const SalidaVehicularEvento({
    required this.id,
    required this.salidaVehicularId,
    this.empleadoId,
    this.empleadoNombre,
    required this.tipoEvento,
    required this.fechaHora,
    this.kilometraje,
    this.latitud,
    this.longitud,
    this.observacion,
  });

  factory SalidaVehicularEvento.fromJson(Map<String, dynamic> json) {
    return SalidaVehicularEvento(
      id: json['id']?.toString() ?? '',
      salidaVehicularId: json['salidaVehicularId']?.toString() ?? '',
      empleadoId: json['empleadoId']?.toString(),
      empleadoNombre: json['empleadoNombre']?.toString(),
      tipoEvento: json['tipoEvento']?.toString() ?? 'EVENTO',
      fechaHora: json['fechaHora'] != null
          ? DateTime.tryParse(json['fechaHora'].toString()) ?? DateTime.now()
          : DateTime.now(),
      kilometraje: (json['kilometraje'] as num?)?.toDouble(),
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
      observacion: json['observacion']?.toString(),
    );
  }
}

class BitacoraVehicular {
  final String id;
  final String salidaVehicularId;
  final String? empleadoId;
  final String? empleadoNombre;
  final String tipo; // ACTIVIDAD | NOVEDAD | INCIDENTE
  final DateTime fechaHora;
  final String descripcion;
  final double? latitud;
  final double? longitud;

  const BitacoraVehicular({
    required this.id,
    required this.salidaVehicularId,
    this.empleadoId,
    this.empleadoNombre,
    required this.tipo,
    required this.fechaHora,
    required this.descripcion,
    this.latitud,
    this.longitud,
  });

  Color get tipoColor {
    switch (tipo.toUpperCase()) {
      case 'INCIDENTE':
        return Colors.red.shade700;
      case 'NOVEDAD':
        return Colors.amber.shade800;
      default:
        return Colors.blue.shade700;
    }
  }

  IconData get tipoIcon {
    switch (tipo.toUpperCase()) {
      case 'INCIDENTE':
        return Icons.warning_rounded;
      case 'NOVEDAD':
        return Icons.info_outline_rounded;
      default:
        return Icons.assignment_outlined;
    }
  }

  factory BitacoraVehicular.fromJson(Map<String, dynamic> json) {
    return BitacoraVehicular(
      id: json['id']?.toString() ?? '',
      salidaVehicularId: json['salidaVehicularId']?.toString() ?? '',
      empleadoId: json['empleadoId']?.toString(),
      empleadoNombre: json['empleadoNombre']?.toString(),
      tipo: json['tipo']?.toString() ?? 'ACTIVIDAD',
      fechaHora: json['fechaHora'] != null
          ? DateTime.tryParse(json['fechaHora'].toString()) ?? DateTime.now()
          : DateTime.now(),
      descripcion: json['descripcion']?.toString() ?? '',
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
    );
  }
}

class WorkflowAction {
  final String name;
  final String variable;
  final String value;

  const WorkflowAction({
    required this.name,
    required this.variable,
    required this.value,
  });

  factory WorkflowAction.fromJson(Map<String, dynamic> json) {
    return WorkflowAction(
      name: json['name']?.toString() ?? '',
      variable: json['variable']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
    );
  }
}

class WorkflowTaskActions {
  final String? taskId;
  final String? taskName;
  final String? taskDefinitionKey;
  final String processInstanceId;
  final String? status;
  final List<WorkflowAction> actions;

  const WorkflowTaskActions({
    this.taskId,
    this.taskName,
    this.taskDefinitionKey,
    required this.processInstanceId,
    this.status,
    this.actions = const [],
  });

  factory WorkflowTaskActions.fromJson(Map<String, dynamic> json) {
    final rawActions = json['actions'];
    final actionsList = rawActions is List
        ? rawActions
            .whereType<Map>()
            .map((a) => WorkflowAction.fromJson(Map<String, dynamic>.from(a)))
            .toList()
        : <WorkflowAction>[];

    return WorkflowTaskActions(
      taskId: json['taskId']?.toString(),
      taskName: json['taskName']?.toString(),
      taskDefinitionKey: json['taskDefinitionKey']?.toString(),
      processInstanceId: json['processInstanceId']?.toString() ?? '',
      status: json['status']?.toString(),
      actions: actionsList,
    );
  }
}

class SalidaVehicularPageResult {
  final List<SalidaVehicular> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  const SalidaVehicularPageResult({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  factory SalidaVehicularPageResult.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'];
    final list = rawContent is List
        ? rawContent
            .whereType<Map>()
            .map((e) => SalidaVehicular.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <SalidaVehicular>[];

    return SalidaVehicularPageResult(
      content: list,
      page: (json['number'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 20,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? list.length,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

class CrearSalidaVehicularInput {
  final String activoId;
  final String? empleadoId;
  final DateTime fecha;
  final String descripcionActividad;
  final String? observaciones;

  const CrearSalidaVehicularInput({
    required this.activoId,
    this.empleadoId,
    required this.fecha,
    required this.descripcionActividad,
    this.observaciones,
  });

  Map<String, dynamic> toJson() {
    return {
      'activoId': activoId,
      if (empleadoId != null && empleadoId!.isNotEmpty) 'empleadoId': empleadoId,
      'fecha': fecha.toIso8601String(),
      'descripcionActividad': descripcionActividad.trim(),
      if (observaciones != null && observaciones!.trim().isNotEmpty)
        'observaciones': observaciones!.trim(),
    };
  }
}

class EjecutarAccionSalidaInput {
  final double? kilometraje;
  final double? latitud;
  final double? longitud;
  final String? observacion;
  final Map<String, dynamic>? variables;

  const EjecutarAccionSalidaInput({
    this.kilometraje,
    this.latitud,
    this.longitud,
    this.observacion,
    this.variables,
  });

  Map<String, dynamic> toJson() {
    return {
      if (kilometraje != null) 'kilometraje': kilometraje,
      if (latitud != null) 'latitud': latitud,
      if (longitud != null) 'longitud': longitud,
      if (observacion != null && observacion!.trim().isNotEmpty)
        'observacion': observacion!.trim(),
      if (variables != null) 'variables': variables,
    };
  }
}

class RegistrarBitacoraInput {
  final String tipo; // ACTIVIDAD | NOVEDAD | INCIDENTE
  final String descripcion;
  final DateTime? fechaHora;
  final double? latitud;
  final double? longitud;

  const RegistrarBitacoraInput({
    required this.tipo,
    required this.descripcion,
    this.fechaHora,
    this.latitud,
    this.longitud,
  });

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo,
      'descripcion': descripcion.trim(),
      'fechaHora': (fechaHora ?? DateTime.now()).toIso8601String(),
      if (latitud != null) 'latitud': latitud,
      if (longitud != null) 'longitud': longitud,
    };
  }
}

