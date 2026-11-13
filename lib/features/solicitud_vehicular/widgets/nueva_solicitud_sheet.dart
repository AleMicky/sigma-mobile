import 'package:flutter/material.dart';
import 'package:sigma_mobile/app/theme/app_theme.dart';
import 'package:sigma_mobile/core/widgets/sigma_widgets.dart';
import 'package:sigma_mobile/features/auth/auth_service.dart';
import 'package:sigma_mobile/features/porteria/models/porteria_models.dart';
import 'package:sigma_mobile/features/solicitud_vehicular/models/solicitud_vehicular_models.dart';
import 'package:sigma_mobile/features/solicitud_vehicular/services/solicitud_vehicular_service.dart';

class NuevaSolicitudSheet extends StatefulWidget {
  final List<TipoSolicitudVehicular> tipos;
  final VoidCallback onCreated;

  const NuevaSolicitudSheet({
    super.key,
    required this.tipos,
    required this.onCreated,
  });

  static Future<bool?> show(
    BuildContext context, {
    required List<TipoSolicitudVehicular> tipos,
    required VoidCallback onCreated,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NuevaSolicitudSheet(
        tipos: tipos,
        onCreated: onCreated,
      ),
    );
  }

  @override
  State<NuevaSolicitudSheet> createState() => _NuevaSolicitudSheetState();
}

class _NuevaSolicitudSheetState extends State<NuevaSolicitudSheet> {
  final _formKey = GlobalKey<FormState>();
  final _service = SolicitudVehicularService.instance;

  final _destinoCtrl = TextEditingController();
  final _motivoCtrl = TextEditingController();
  final _justificacionCtrl = TextEditingController();
  final _observacionCtrl = TextEditingController();

  TipoSolicitudVehicular? _selectedTipo;
  FuncionarioOption? _selectedSolicitante;
  bool _loadingSolicitantes = false;
  List<FuncionarioOption> _empleadosList = const [];

  ConductorOption? _selectedConductor;
  bool _loadingConductores = false;
  List<ConductorOption> _conductoresList = const [];

  int _cantidadPasajeros = 1;
  late DateTime _fechaSalida;
  late DateTime _fechaRetorno;

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Default: Salida mañana a las 08:00, Retorno mañana a las 18:00
    _fechaSalida = DateTime(now.year, now.month, now.day + 1, 8, 0);
    _fechaRetorno = DateTime(now.year, now.month, now.day + 1, 18, 0);

    if (widget.tipos.isNotEmpty) {
      _selectedTipo = widget.tipos.first;
      _adjustSalidaForAnticipacion();
    }

    _loadEmpleados();
    _loadConductores();
  }

  @override
  void dispose() {
    _destinoCtrl.dispose();
    _motivoCtrl.dispose();
    _justificacionCtrl.dispose();
    _observacionCtrl.dispose();
    super.dispose();
  }

  void _adjustSalidaForAnticipacion() {
    if (_selectedTipo == null) return;
    final dias = _selectedTipo!.diasAnticipacion;
    final now = DateTime.now();
    final minDate = now.add(Duration(days: dias > 0 ? dias : 0));
    if (_fechaSalida.isBefore(minDate)) {
      _fechaSalida = DateTime(
        minDate.year,
        minDate.month,
        minDate.day,
        8,
        0,
      );
      if (_fechaRetorno.isBefore(_fechaSalida)) {
        _fechaRetorno = _fechaSalida.add(const Duration(hours: 8));
      }
    }
  }

  Future<void> _loadEmpleados() async {
    setState(() => _loadingSolicitantes = true);
    try {
      final list = await _service.buscarEmpleados(size: 50);
      if (!mounted) return;
      setState(() {
        _empleadosList = list;
        _loadingSolicitantes = false;

        // Auto-seleccionar al usuario actual si coincide por nombre o username
        final currentUser = AuthService.instance.user;
        final currentName = currentUser?['name']?.toString().toLowerCase().trim() ?? '';
        final currentUsername = currentUser?['username']?.toString().toLowerCase().trim() ?? '';

        if (list.isNotEmpty) {
          final match = list.firstWhere(
            (e) {
              final nombre = e.nombreCompleto.toLowerCase();
              final cod = e.codigo.toLowerCase();
              return (currentName.isNotEmpty && nombre.contains(currentName)) ||
                  (currentUsername.isNotEmpty && (cod == currentUsername || nombre.contains(currentUsername)));
            },
            orElse: () => list.first,
          );
          _selectedSolicitante = match;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loadingSolicitantes = false);
    }
  }

  Future<void> _loadConductores() async {
    setState(() => _loadingConductores = true);
    try {
      final list = await _service.listarConductores(
        fechaSalida: _fechaSalida,
        fechaRetorno: _fechaRetorno,
      );
      if (!mounted) return;
      setState(() {
        _conductoresList = list;
        _loadingConductores = false;

        // Si ya hay un conductor seleccionado, mantenerlo sincronizado
        if (_selectedConductor != null && list.isNotEmpty) {
          final found = list.where((c) => c.id == _selectedConductor!.id);
          if (found.isNotEmpty) {
            _selectedConductor = found.first;
          }
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loadingConductores = false);
    }
  }

  Future<void> _abrirSelectorConductor() async {
    final picked = await showModalBottomSheet<ConductorOption?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SelectorConductorSheet(
        conductores: _conductoresList,
        selectedId: _selectedConductor?.id,
        onRefreshDisponibles: () => _service.listarConductores(
          fechaSalida: _fechaSalida,
          fechaRetorno: _fechaRetorno,
        ),
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedConductor = picked.id.isEmpty ? null : picked;
      });
    }
  }

  Future<void> _pickDateTime({required bool isSalida}) async {
    final initialDate = isSalida ? _fechaSalida : _fechaRetorno;
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      helpText: isSalida ? 'Seleccionar fecha de salida' : 'Seleccionar fecha de retorno',
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
      helpText: isSalida ? 'Seleccionar hora de salida' : 'Seleccionar hora de retorno',
    );

    if (pickedTime == null || !mounted) return;

    final newDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isSalida) {
        _fechaSalida = newDateTime;
        if (_fechaRetorno.isBefore(_fechaSalida) || _fechaRetorno.isAtSameMomentAs(_fechaSalida)) {
          _fechaRetorno = _fechaSalida.add(const Duration(hours: 4));
        }
      } else {
        _fechaRetorno = newDateTime;
      }
    });

    _loadConductores();
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y  $h:$min';
  }

  String _calcDuracion() {
    final diff = _fechaRetorno.difference(_fechaSalida);
    if (diff.isNegative || diff.inMinutes == 0) {
      return 'Retorno debe ser posterior a la salida';
    }
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final mins = diff.inMinutes % 60;
    final parts = <String>[];
    if (days > 0) parts.add('$days ${days == 1 ? "día" : "días"}');
    if (hours > 0) parts.add('$hours ${hours == 1 ? "hora" : "horas"}');
    if (mins > 0 && days == 0) parts.add('$mins min');
    return parts.isNotEmpty ? parts.join(', ') : '< 1 min';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTipo == null) {
      setState(() => _errorMessage = 'Debe seleccionar un tipo de solicitud');
      return;
    }

    if (_selectedSolicitante == null) {
      setState(() => _errorMessage = 'Debe seleccionar un solicitante');
      return;
    }

    if (_fechaRetorno.isBefore(_fechaSalida) || _fechaRetorno.isAtSameMomentAs(_fechaSalida)) {
      setState(() => _errorMessage = 'La fecha de retorno debe ser posterior a la salida');
      return;
    }

    // Validación de anticipación
    final diasAnticipacion = _selectedTipo!.diasAnticipacion;
    if (diasAnticipacion > 0) {
      final now = DateTime.now();
      final minSalida = DateTime(now.year, now.month, now.day).add(Duration(days: diasAnticipacion));
      if (_fechaSalida.isBefore(minSalida)) {
        setState(() => _errorMessage =
            'Este tipo requiere al menos $diasAnticipacion día(s) de anticipación. Salida mínima: ${_formatDateTime(minSalida)}');
        return;
      }
    }

    // Validación de justificación obligatoria
    if (_selectedTipo!.requiereJustificacion && _justificacionCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = 'La justificación es requerida para este tipo de solicitud');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final input = CrearSolicitudVehicularInput(
        tipoSolicitudVehicularId: _selectedTipo!.id,
        solicitanteId: _selectedSolicitante!.id,
        conductorAsignadoId: _selectedConductor?.id,
        motivo: _motivoCtrl.text.trim(),
        justificacion: _justificacionCtrl.text.trim().isNotEmpty
            ? _justificacionCtrl.text.trim()
            : null,
        destino: _destinoCtrl.text.trim(),
        fechaSalida: _fechaSalida,
        fechaRetornoEstimada: _fechaRetorno,
        cantidadPasajeros: _cantidadPasajeros,
        observacion: _observacionCtrl.text.trim().isNotEmpty
            ? _observacionCtrl.text.trim()
            : null,
      );

      await _service.crear(input);
      widget.onCreated();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = SolicitudVehicularService.extractErrorMessage(e);
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: keyboardSpace),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Barra superior deslizable
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Encabezado
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.accentGold.withValues(alpha: 0.15)
                            : AppTheme.secondary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.add_road_rounded,
                        color: isDark ? AppTheme.accentGold : AppTheme.secondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nueva Solicitud Vehicular',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Ingresa los datos del viaje y pasajeros',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Contenido con Scroll
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    children: [
                      // Mensaje de Error
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50.withValues(alpha: isDark ? 0.15 : 1.0),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline_rounded,
                                  color: Colors.red.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: isDark ? Colors.red.shade300 : Colors.red.shade800,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // SECCIÓN 1: Clasificación
                      _buildSectionHeader('1. Tipo, Solicitante y Conductor', Icons.category_rounded),
                      const SizedBox(height: 8),

                      // Tipo de Solicitud Selector
                      const Text(
                        'Tipo de Solicitud *',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<TipoSolicitudVehicular>(
                        value: _selectedTipo,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.assignment_outlined, size: 20),
                        ),
                        items: widget.tipos.map((tipo) {
                          return DropdownMenuItem(
                            value: tipo,
                            child: Text(
                              '${tipo.nombre} (${tipo.codigo})',
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedTipo = val;
                              _adjustSalidaForAnticipacion();
                            });
                          }
                        },
                      ),

                      // Badges informativos del tipo
                      if (_selectedTipo != null) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _selectedTipo!.esEmergencia
                                    ? Colors.red.shade100.withValues(alpha: isDark ? 0.2 : 0.8)
                                    : Colors.amber.shade100.withValues(alpha: isDark ? 0.2 : 0.8),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _selectedTipo!.esEmergencia
                                      ? Colors.red.shade400
                                      : Colors.amber.shade400,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _selectedTipo!.esEmergencia
                                        ? Icons.local_fire_department_rounded
                                        : Icons.schedule_rounded,
                                    size: 13,
                                    color: _selectedTipo!.esEmergencia
                                        ? Colors.red.shade700
                                        : Colors.amber.shade900,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _selectedTipo!.esEmergencia
                                        ? 'Inmediato (Emergencia)'
                                        : 'Anticipación: ${_selectedTipo!.diasAnticipacion}d',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _selectedTipo!.esEmergencia
                                          ? (isDark ? Colors.red.shade300 : Colors.red.shade900)
                                          : (isDark ? Colors.amber.shade300 : Colors.amber.shade900),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_selectedTipo!.requiereJustificacion)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade50.withValues(alpha: isDark ? 0.2 : 0.8),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.purple.shade300),
                                ),
                                child: Text(
                                  'Requiere Justificación',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.purple.shade300 : Colors.purple.shade900,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Solicitante Selector
                      const Text(
                        'Funcionario Solicitante *',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      if (_loadingSolicitantes)
                        const LinearProgressIndicator(minHeight: 2)
                      else
                        DropdownButtonFormField<FuncionarioOption>(
                          value: _selectedSolicitante,
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                          ),
                          items: _empleadosList.map((emp) {
                            return DropdownMenuItem(
                              value: emp,
                              child: Text(
                                '${emp.nombreCompleto} (${emp.codigo})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedSolicitante = val);
                          },
                        ),
                      const SizedBox(height: 12),

                      // Conductor Selector
                      Row(
                        children: [
                          const Text(
                            'Conductor Asignado',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Opcional',
                              style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (_loadingConductores)
                        const LinearProgressIndicator(minHeight: 2)
                      else
                        InkWell(
                          onTap: _abrirSelectorConductor,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? Colors.white24 : Colors.grey.shade400,
                              ),
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF8FAFC),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.badge_outlined,
                                  size: 20,
                                  color: _selectedConductor != null
                                      ? (isDark ? AppTheme.accentGold : const Color(0xFF0F766E))
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _selectedConductor == null
                                      ? Text(
                                          _conductoresList.isEmpty
                                              ? 'Sin conductor asignado (asignar después)'
                                              : 'Seleccionar conductor asignado...',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                                          ),
                                        )
                                      : Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _selectedConductor!.nombreCompleto,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            if (_selectedConductor!.subtitulo.isNotEmpty)
                                              Text(
                                                _selectedConductor!.subtitulo,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark ? Colors.white60 : Colors.grey.shade700,
                                                ),
                                              ),
                                          ],
                                        ),
                                ),
                                if (_selectedConductor != null)
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 18),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => setState(() => _selectedConductor = null),
                                    tooltip: 'Quitar conductor',
                                  )
                                else
                                  const Icon(Icons.arrow_drop_down_rounded),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 18),

                      // SECCIÓN 2: Itinerario y Fechas
                      _buildSectionHeader('2. Itinerario y Pasajeros', Icons.map_rounded),
                      const SizedBox(height: 8),

                      // Destino
                      const Text(
                        'Destino o Ruta del Viaje *',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _destinoCtrl,
                        decoration: InputDecoration(
                          hintText: 'Ej. Planta Corani / Subestación Santiváñez',
                          prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'El destino es obligatorio';
                          if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // N° Pasajeros (Control móvil táctil)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cantidad de Pasajeros *',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'Incluye al personal que viajará',
                                style: TextStyle(fontSize: 10.5, color: Colors.grey),
                              ),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? Colors.white24 : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 18),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: _cantidadPasajeros > 1
                                      ? () => setState(() => _cantidadPasajeros--)
                                      : null,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    '$_cantidadPasajeros',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 18),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: _cantidadPasajeros < 40
                                      ? () => setState(() => _cantidadPasajeros++)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Fechas Salida y Retorno (Botones táctiles)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Fecha y Hora de Salida *',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () => _pickDateTime(isSalida: true),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF0284C7)),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            _formatDateTime(_fechaSalida),
                                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Retorno Estimado *',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () => _pickDateTime(isSalida: false),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.event_repeat_rounded, size: 16, color: Color(0xFF059669)),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            _formatDateTime(_fechaRetorno),
                                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Chip de duración calculada
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: isDark ? 0.2 : 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timelapse_rounded, size: 14, color: Color(0xFF0284C7)),
                            const SizedBox(width: 6),
                            Text(
                              'Duración estimada: ${_calcDuracion()}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // SECCIÓN 3: Motivo & Justificación
                      _buildSectionHeader('3. Motivo y Justificación', Icons.description_rounded),
                      const SizedBox(height: 8),

                      // Motivo
                      const Text(
                        'Motivo / Asunto del Viaje *',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _motivoCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Ej. Inspección y mantenimiento preventivo en Planta Corani',
                          contentPadding: const EdgeInsets.all(10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'El motivo es obligatorio';
                          if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Justificación (Condicional / Recomendada)
                      Row(
                        children: [
                          const Text(
                            'Justificación Operativa',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          if (_selectedTipo?.requiereJustificacion == true)
                            const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _justificacionCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: _selectedTipo?.requiereJustificacion == true
                              ? 'Detalla la justificación técnica de la urgencia o requerimiento...'
                              : 'Opcional. Motivos técnicos o complementarios...',
                          contentPadding: const EdgeInsets.all(10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) {
                          if (_selectedTipo?.requiereJustificacion == true &&
                              (v == null || v.trim().isEmpty)) {
                            return 'La justificación es obligatoria para este tipo';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Observaciones
                      const Text(
                        'Observaciones Adicionales',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _observacionCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Equipos o herramientas a trasladar, paradas intermedias, etc.',
                          contentPadding: const EdgeInsets.all(10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Botón inferior
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark ? AppTheme.accentGold : AppTheme.primary,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Registrar Solicitud',
                                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF0284C7)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _SelectorConductorSheet extends StatefulWidget {
  final List<ConductorOption> conductores;
  final String? selectedId;
  final Future<List<ConductorOption>> Function()? onRefreshDisponibles;

  const _SelectorConductorSheet({
    required this.conductores,
    this.selectedId,
    this.onRefreshDisponibles,
  });

  @override
  State<_SelectorConductorSheet> createState() => _SelectorConductorSheetState();
}

class _SelectorConductorSheetState extends State<_SelectorConductorSheet> {
  String _filter = '';
  late List<ConductorOption> _items;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.conductores);
  }

  @override
  void didUpdateWidget(covariant _SelectorConductorSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conductores != widget.conductores) {
      _items = List.of(widget.conductores);
    }
  }

  Future<void> _refresh() async {
    if (widget.onRefreshDisponibles == null) return;
    setState(() => _refreshing = true);
    try {
      final updated = await widget.onRefreshDisponibles!();
      if (mounted) {
        setState(() {
          _items = updated;
          _refreshing = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final q = _filter.trim().toLowerCase();

    final filtered = _items.where((c) {
      if (q.isEmpty) return true;
      final matchNombre = c.nombreCompleto.toLowerCase().contains(q);
      final matchCodigo = c.codigo != null && c.codigo!.toLowerCase().contains(q);
      final matchLic = c.numeroLicencia != null && c.numeroLicencia!.toLowerCase().contains(q);
      final matchCargo = c.cargo != null && c.cargo!.toLowerCase().contains(q);
      return matchNombre || matchCodigo || matchLic || matchCargo;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra superior deslizable
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Encabezado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.badge_outlined, size: 18, color: Color(0xFF0F766E)),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seleccionar Conductor',
                        style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Conductores disponibles para el viaje',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (widget.onRefreshDisponibles != null)
                  IconButton(
                    icon: _refreshing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, size: 20),
                    onPressed: _refreshing ? null : _refresh,
                    tooltip: 'Recargar disponibles',
                  ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Buscador
            TextField(
              onChanged: (val) => setState(() => _filter = val),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, código o licencia...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),

            // Opción: Sin conductor asignado
            InkWell(
              onTap: () => Navigator.pop(context, const ConductorOption(id: '', nombreCompleto: '')),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: widget.selectedId == null || widget.selectedId!.isEmpty
                      ? (isDark ? Colors.white10 : Colors.grey.shade100)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_off_outlined,
                      size: 18,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Sin conductor asignado (asignar después)',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (widget.selectedId == null || widget.selectedId!.isEmpty)
                      const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF0F766E)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Lista de Conductores
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_search_outlined, size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            Text(
                              _items.isEmpty
                                  ? 'No hay conductores registrados en el sistema'
                                  : 'No se encontraron conductores con "$_filter"',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final c = filtered[i];
                        final isSelected = c.id == widget.selectedId;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          onTap: () => Navigator.pop(context, c),
                          selected: isSelected,
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.15),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 20,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                          title: Text(
                            c.nombreCompleto,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: c.subtitulo.isNotEmpty
                              ? Text(
                                  c.subtitulo,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                )
                              : null,
                          trailing: isSelected
                              ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0F766E), size: 20)
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

