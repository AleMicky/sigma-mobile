enum EstadoRegistroPorteria {
  afuera('AFUERA', 'Afuera'),
  completado('COMPLETADO', 'Completado'),
  anulado('ANULADO', 'Anulado');

  final String value;
  final String label;

  const EstadoRegistroPorteria(this.value, this.label);

  static EstadoRegistroPorteria fromString(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'COMPLETADO':
        return EstadoRegistroPorteria.completado;
      case 'ANULADO':
        return EstadoRegistroPorteria.anulado;
      case 'AFUERA':
      default:
        return EstadoRegistroPorteria.afuera;
    }
  }
}

class RegistroPorteriaActivo {
  final String id;
  final String? activoId;
  final String? activoCodigo;
  final String? activoNombre;
  final String? descripcionItem;
  final int cantidad;
  final String? observacionSalida;
  final bool? retornado;
  final String? observacionLlegada;

  const RegistroPorteriaActivo({
    required this.id,
    this.activoId,
    this.activoCodigo,
    this.activoNombre,
    this.descripcionItem,
    this.cantidad = 1,
    this.observacionSalida,
    this.retornado,
    this.observacionLlegada,
  });

  bool get esCatalogado =>
      activoNombre != null && activoNombre!.trim().isNotEmpty;

  String get displayVehiculoNombre {
    if (esCatalogado) {
      final clean = activoNombre!.replaceAll(RegExp(r'PLACA.*$', caseSensitive: false), '').trim();
      return clean.isNotEmpty ? clean : activoNombre!.trim();
    }
    return (descripcionItem != null && descripcionItem!.trim().isNotEmpty)
        ? descripcionItem!.trim()
        : 'Vehículo';
  }

  String get displayPlaca {
    final text = '${activoNombre ?? ''} ${descripcionItem ?? ''}';
    final match = RegExp(
      r'PLACA(?:\s*(?:N[°o.]+|NRO\.?|NUM\.?|#))?[:\s#.-]+([0-9A-Za-z]+(?:[\s-][0-9A-Za-z]+)?)',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null && match.group(1) != null) {
      final clean = match.group(1)!.replaceAll(RegExp(r'[,.;-]+$'), '').trim();
      if (clean.length >= 2 && clean.length <= 15 && !clean.toUpperCase().startsWith('NO')) {
        return clean.toUpperCase();
      }
    }
    final matchBol = RegExp(r'\b([0-9]{3,4}[-\s]?[A-Z]{3})\b', caseSensitive: false).firstMatch(text);
    if (matchBol != null && matchBol.group(1) != null) {
      return matchBol.group(1)!.toUpperCase().replaceAll(' ', '-');
    }
    return activoCodigo ?? '';
  }

  String get displayTipo {
    final text = '${activoNombre ?? ''} ${descripcionItem ?? ''}'.toUpperCase();
    if (text.contains('CAMIONETA')) return 'Camioneta';
    if (text.contains('VAGONETA')) return 'Vagoneta';
    if (text.contains('AUTO')) return 'Automóvil';
    if (text.contains('MINIBUS')) return 'Minibús';
    if (text.contains('CAMION')) return 'Camión';
    if (text.contains('MOTO')) return 'Motocicleta';
    return 'Vehículo';
  }

  String get displayLabel {
    if (esCatalogado) {
      final code = activoCodigo?.trim() ?? '';
      final name = activoNombre?.trim() ?? '';
      return code.isNotEmpty ? '$code · $name' : name;
    }
    return (descripcionItem != null && descripcionItem!.trim().isNotEmpty)
        ? descripcionItem!.trim()
        : 'Ítem';
  }

  String get displayShortName {
    if (esCatalogado) {
      return activoNombre!.trim();
    }
    return (descripcionItem != null && descripcionItem!.trim().isNotEmpty)
        ? descripcionItem!.trim()
        : 'Ítem';
  }

  factory RegistroPorteriaActivo.fromJson(Map<String, dynamic> json) {
    return RegistroPorteriaActivo(
      id: json['id']?.toString() ?? '',
      activoId: json['activoId']?.toString(),
      activoCodigo: json['activoCodigo']?.toString(),
      activoNombre: json['activoNombre']?.toString(),
      descripcionItem: json['descripcionItem']?.toString(),
      cantidad: (json['cantidad'] as num?)?.toInt() ?? 1,
      observacionSalida: json['observacionSalida']?.toString(),
      retornado: json['retornado'] is bool ? json['retornado'] as bool : null,
      observacionLlegada: json['observacionLlegada']?.toString(),
    );
  }
}

class RegistroPorteria {
  final String id;
  final String numero;
  final String? empleadoId;
  final String? empleadoNombre;
  final bool esExterno;
  final String? personaExterna;
  final String? placaExterna;
  final String? guardiaSalidaId;
  final String? guardiaSalidaNombre;
  final String? guardiaLlegadaId;
  final String? guardiaLlegadaNombre;
  final String? salidaVehicularId;
  final DateTime fechaHoraSalida;
  final DateTime? fechaHoraLlegada;
  final EstadoRegistroPorteria estado;
  final String? observacionSalida;
  final String? observacionLlegada;
  final List<RegistroPorteriaActivo> activos;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RegistroPorteria({
    required this.id,
    required this.numero,
    this.empleadoId,
    this.empleadoNombre,
    this.esExterno = false,
    this.personaExterna,
    this.placaExterna,
    this.guardiaSalidaId,
    this.guardiaSalidaNombre,
    this.guardiaLlegadaId,
    this.guardiaLlegadaNombre,
    this.salidaVehicularId,
    required this.fechaHoraSalida,
    this.fechaHoraLlegada,
    required this.estado,
    this.observacionSalida,
    this.observacionLlegada,
    required this.activos,
    this.createdAt,
    this.updatedAt,
  });

  String get funcionarioDisplay {
    if (esExterno && personaExterna != null && personaExterna!.trim().isNotEmpty) {
      return personaExterna!.trim();
    }
    return (empleadoNombre != null && empleadoNombre!.trim().isNotEmpty)
        ? empleadoNombre!.trim()
        : (empleadoId ?? '');
  }

  int get totalUnidades =>
      activos.fold<int>(0, (sum, item) => sum + item.cantidad);

  factory RegistroPorteria.fromJson(Map<String, dynamic> json) {
    final rawActivos = json['activos'];
    final activosList = rawActivos is List
        ? rawActivos
              .whereType<Map>()
              .map(
                (item) => RegistroPorteriaActivo.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : <RegistroPorteriaActivo>[];

    return RegistroPorteria(
      id: json['id']?.toString() ?? '',
      numero: json['numero']?.toString() ?? '',
      empleadoId: json['empleadoId']?.toString(),
      empleadoNombre: json['empleadoNombre']?.toString(),
      esExterno: json['esExterno'] == true,
      personaExterna: json['personaExterna']?.toString(),
      placaExterna: json['placaExterna']?.toString(),
      guardiaSalidaId: json['guardiaSalidaId']?.toString(),
      guardiaSalidaNombre: json['guardiaSalidaNombre']?.toString(),
      guardiaLlegadaId: json['guardiaLlegadaId']?.toString(),
      guardiaLlegadaNombre: json['guardiaLlegadaNombre']?.toString(),
      salidaVehicularId: json['salidaVehicularId']?.toString(),
      fechaHoraSalida:
          DateTime.tryParse(json['fechaHoraSalida']?.toString() ?? '')
              ?.toLocal() ??
          DateTime.now(),
      fechaHoraLlegada: json['fechaHoraLlegada'] != null
          ? DateTime.tryParse(json['fechaHoraLlegada'].toString())?.toLocal()
          : null,
      estado: EstadoRegistroPorteria.fromString(json['estado']?.toString()),
      observacionSalida: json['observacionSalida']?.toString(),
      observacionLlegada: json['observacionLlegada']?.toString(),
      activos: activosList,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())?.toLocal()
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())?.toLocal()
          : null,
    );
  }
}

class RegistroPorteriaActivoSalidaInput {
  final String? activoId;
  final String? descripcionItem;
  final int cantidad;
  final String? observacionSalida;

  const RegistroPorteriaActivoSalidaInput({
    this.activoId,
    this.descripcionItem,
    this.cantidad = 1,
    this.observacionSalida,
  });

  Map<String, dynamic> toJson() {
    return {
      if (activoId != null && activoId!.isNotEmpty) 'activoId': activoId,
      if (descripcionItem != null && descripcionItem!.trim().isNotEmpty)
        'descripcionItem': descripcionItem!.trim(),
      'cantidad': cantidad > 0 ? cantidad : 1,
      if (observacionSalida != null && observacionSalida!.trim().isNotEmpty)
        'observacionSalida': observacionSalida!.trim(),
    };
  }
}

class RegistrarSalidaPorteriaInput {
  final String? empleadoId;
  final bool esExterno;
  final String? personaExterna;
  final String? placaExterna;
  final DateTime? fechaHoraSalida;
  final String? salidaVehicularId;
  final String? observacionSalida;
  final List<RegistroPorteriaActivoSalidaInput> activos;

  const RegistrarSalidaPorteriaInput({
    this.empleadoId,
    this.esExterno = false,
    this.personaExterna,
    this.placaExterna,
    this.fechaHoraSalida,
    this.salidaVehicularId,
    this.observacionSalida,
    this.activos = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'esExterno': esExterno,
      if (empleadoId != null && empleadoId!.isNotEmpty) 'empleadoId': empleadoId,
      if (personaExterna != null && personaExterna!.trim().isNotEmpty)
        'personaExterna': personaExterna!.trim(),
      if (placaExterna != null && placaExterna!.trim().isNotEmpty)
        'placaExterna': placaExterna!.trim(),
      if (fechaHoraSalida != null)
        'fechaHoraSalida': fechaHoraSalida!.toUtc().toIso8601String(),
      if (salidaVehicularId != null && salidaVehicularId!.isNotEmpty)
        'salidaVehicularId': salidaVehicularId,
      if (observacionSalida != null && observacionSalida!.trim().isNotEmpty)
        'observacionSalida': observacionSalida!.trim(),
      'activos': activos.map((a) => a.toJson()).toList(),
    };
  }
}

class RegistroPorteriaActivoLlegadaInput {
  final String itemId;
  final bool retornado;
  final String? observacionLlegada;

  const RegistroPorteriaActivoLlegadaInput({
    required this.itemId,
    required this.retornado,
    this.observacionLlegada,
  });

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'retornado': retornado,
      if (observacionLlegada != null && observacionLlegada!.trim().isNotEmpty)
        'observacionLlegada': observacionLlegada!.trim(),
    };
  }
}

class RegistrarLlegadaPorteriaInput {
  final DateTime? fechaHoraLlegada;
  final String? observacionLlegada;
  final List<RegistroPorteriaActivoLlegadaInput> activos;

  const RegistrarLlegadaPorteriaInput({
    this.fechaHoraLlegada,
    this.observacionLlegada,
    required this.activos,
  });

  Map<String, dynamic> toJson() {
    return {
      if (fechaHoraLlegada != null)
        'fechaHoraLlegada': fechaHoraLlegada!.toUtc().toIso8601String(),
      if (observacionLlegada != null && observacionLlegada!.trim().isNotEmpty)
        'observacionLlegada': observacionLlegada!.trim(),
      'activos': activos.map((a) => a.toJson()).toList(),
    };
  }
}

class PorteriaPageResult {
  final List<RegistroPorteria> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool first;
  final bool last;

  const PorteriaPageResult({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    this.first = true,
    this.last = true,
  });

  factory PorteriaPageResult.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'];
    final items = rawContent is List
        ? rawContent
              .whereType<Map>()
              .map(
                (item) => RegistroPorteria.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : <RegistroPorteria>[];

    return PorteriaPageResult(
      content: items,
      page: (json['page'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 20,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? items.length,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      first: json['first'] is bool ? json['first'] as bool : true,
      last: json['last'] is bool ? json['last'] as bool : true,
    );
  }
}

class FuncionarioOption {
  final String id;
  final String codigo;
  final String nombreCompleto;
  final String? cargo;
  final String? area;

  const FuncionarioOption({
    required this.id,
    required this.codigo,
    required this.nombreCompleto,
    this.cargo,
    this.area,
  });

  String get subtitle {
    final parts = [
      if (cargo != null && cargo!.trim().isNotEmpty) cargo!.trim(),
      if (area != null && area!.trim().isNotEmpty) area!.trim(),
    ];
    return parts.join(' · ');
  }

  factory FuncionarioOption.fromJson(Map<String, dynamic> json) {
    final personaInfo = json['personaInfo'];
    final cargoInfo = json['cargoInfo'];
    final areaInfo = json['areaInfo'];

    final codigo = json['codigo']?.toString() ?? '';
    final nombre =
        (personaInfo is Map ? personaInfo['nombreCompleto']?.toString() : null) ??
        json['personaNombreCompleto']?.toString() ??
        json['nombreCompleto']?.toString() ??
        'Funcionario ($codigo)';

    final cargo =
        (cargoInfo is Map ? cargoInfo['nombre']?.toString() : null) ??
        json['cargoNombre']?.toString();
    final area =
        (areaInfo is Map ? areaInfo['nombre']?.toString() : null) ??
        json['areaNombre']?.toString();

    return FuncionarioOption(
      id: json['id']?.toString() ?? '',
      codigo: codigo,
      nombreCompleto: nombre,
      cargo: cargo,
      area: area,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FuncionarioOption && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class ActivoOption {
  final String id;
  final String codigo;
  final String nombre;
  final String? descripcion;
  final String? tipoNombre;
  final String? urlImagen;
  final String? placa;

  const ActivoOption({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    this.tipoNombre,
    this.urlImagen,
    this.placa,
  });

  String get displayVehiculoNombre {
    final clean = nombre.replaceAll(RegExp(r'PLACA.*$', caseSensitive: false), '').trim();
    return clean.isNotEmpty ? clean : nombre;
  }

  String get displayPlaca {
    if (placa != null && placa!.trim().isNotEmpty) return placa!.trim().toUpperCase();
    final p = _extractPlaca(descripcion, nombre, codigo);
    return (p != null && p.isNotEmpty) ? p : codigo;
  }

  String get displayTipo {
    if (tipoNombre != null && tipoNombre!.trim().isNotEmpty && !tipoNombre!.toLowerCase().contains('general')) {
      return tipoNombre!.trim();
    }
    final text = '$nombre ${descripcion ?? ''}'.toUpperCase();
    if (text.contains('CAMIONETA')) return 'Camioneta';
    if (text.contains('VAGONETA')) return 'Vagoneta';
    if (text.contains('AUTO')) return 'Automóvil';
    if (text.contains('MINIBUS')) return 'Minibús';
    if (text.contains('CAMION')) return 'Camión';
    if (text.contains('MOTO')) return 'Motocicleta';
    return tipoNombre ?? 'Vehículo';
  }

  String get displayLabel => '$displayVehiculoNombre · $displayPlaca';

  factory ActivoOption.fromJson(Map<String, dynamic> json) {
    final tipoActivo = json['tipoActivo'];
    final desc = json['descripcion']?.toString();
    final nom = json['nombre']?.toString() ?? '';
    final cod = json['codigo']?.toString() ?? '';
    final rawPlaca = json['placa']?.toString();
    final rawImg = json['urlImagen']?.toString() ??
        json['imagenUrl']?.toString() ??
        json['fotoUrl']?.toString();

    return ActivoOption(
      id: json['id']?.toString() ?? '',
      codigo: cod,
      nombre: nom,
      descripcion: desc,
      tipoNombre: tipoActivo is Map ? tipoActivo['nombre']?.toString() : null,
      urlImagen: rawImg,
      placa: rawPlaca ?? _extractPlaca(desc, nom, cod),
    );
  }

  static String? _extractPlaca(String? desc, String? name, String? cod) {
    final text = '${desc ?? ''} ${name ?? ''}';
    final match = RegExp(
      r'PLACA(?:\s*(?:N[°o.]+|NRO\.?|NUM\.?|#))?[:\s#.-]+([0-9A-Za-z]+(?:[\s-][0-9A-Za-z]+)?)',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null && match.group(1) != null) {
      final clean = match.group(1)!.replaceAll(RegExp(r'[,.;-]+$'), '').trim();
      if (clean.length >= 2 && clean.length <= 15 && !clean.toUpperCase().startsWith('NO')) {
        return clean.toUpperCase();
      }
    }
    final matchBol = RegExp(r'\b([0-9]{3,4}[-\s]?[A-Z]{3})\b', caseSensitive: false).firstMatch(text);
    if (matchBol != null && matchBol.group(1) != null) {
      return matchBol.group(1)!.toUpperCase().replaceAll(' ', '-');
    }
    return null;
  }
}

