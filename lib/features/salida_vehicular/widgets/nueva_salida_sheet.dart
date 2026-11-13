import 'package:flutter/material.dart';
import 'package:sigma_mobile/app/theme/app_theme.dart';
import 'package:sigma_mobile/core/widgets/sigma_card.dart';
import 'package:sigma_mobile/core/widgets/sigma_primary_button.dart';
import 'package:sigma_mobile/core/widgets/sigma_text_field.dart';
import 'package:sigma_mobile/features/auth/auth_service.dart';
import 'package:sigma_mobile/features/porteria/models/porteria_models.dart';
import 'package:sigma_mobile/features/porteria/widgets/vehiculo_display_widgets.dart';
import 'package:sigma_mobile/features/salida_vehicular/models/salida_vehicular_models.dart';
import 'package:sigma_mobile/features/salida_vehicular/services/salida_vehicular_service.dart';

class NuevaSalidaSheet extends StatefulWidget {
  final VoidCallback? onSalidaCreada;

  const NuevaSalidaSheet({super.key, this.onSalidaCreada});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NuevaSalidaSheet(),
    );
  }

  @override
  State<NuevaSalidaSheet> createState() => _NuevaSalidaSheetState();
}

class _NuevaSalidaSheetState extends State<NuevaSalidaSheet> {
  final _service = SalidaVehicularService.instance;
  final _auth = AuthService.instance;

  final _actividadController = TextEditingController();
  final _observacionesController = TextEditingController();

  DateTime _fecha = DateTime.now();
  TimeOfDay _hora = TimeOfDay.now();

  ActivoOption? _selectedVehiculo;
  FuncionarioOption? _selectedConductor;

  List<ActivoOption> _vehiculos = [];
  List<FuncionarioOption> _conductores = [];
  bool _cargandoCatalogos = true;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarCatalogos();
  }

  @override
  void dispose() {
    _actividadController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _cargarCatalogos() async {
    try {
      final results = await Future.wait([
        _service.listarVehiculos(),
        _service.listarEmpleados(),
      ]);

      if (!mounted) return;

      final vehiculosList = results[0] as List<ActivoOption>;
      final conductoresList = results[1] as List<FuncionarioOption>;

      // Auto-seleccionar conductor si coincide con el usuario autenticado
      final currentUserId = _auth.user?['id']?.toString();
      FuncionarioOption? defaultConductor;
      if (currentUserId != null) {
        for (final c in conductoresList) {
          if (c.id == currentUserId) {
            defaultConductor = c;
            break;
          }
        }
      }

      setState(() {
        _vehiculos = vehiculosList;
        _conductores = conductoresList;
        _selectedConductor = defaultConductor ?? (conductoresList.isNotEmpty ? conductoresList.first : null);
        _cargandoCatalogos = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _cargandoCatalogos = false);
      }
    }
  }

  DateTime get _fechaHoraFinal {
    return DateTime(
      _fecha.year,
      _fecha.month,
      _fecha.day,
      _hora.hour,
      _hora.minute,
    );
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && mounted) {
      setState(() => _fecha = picked);
    }
  }

  Future<void> _seleccionarHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _hora,
    );
    if (picked != null && mounted) {
      setState(() => _hora = picked);
    }
  }

  Future<void> _abrirSelectorVehiculo() async {
    final picked = await showModalBottomSheet<ActivoOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SelectorVehiculoSheet(
        vehiculos: _vehiculos,
        selectedId: _selectedVehiculo?.id,
      ),
    );

    if (picked != null && mounted) {
      setState(() => _selectedVehiculo = picked);
    }
  }

  Future<void> _abrirSelectorConductor() async {
    final picked = await showModalBottomSheet<FuncionarioOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SelectorConductorSheet(
        conductores: _conductores,
        selectedId: _selectedConductor?.id,
      ),
    );

    if (picked != null && mounted) {
      setState(() => _selectedConductor = picked);
    }
  }

  Future<void> _guardar() async {
    if (_selectedVehiculo == null) {
      setState(() => _error = 'Debes seleccionar el vehículo de la salida.');
      return;
    }

    final actividad = _actividadController.text.trim();
    if (actividad.isEmpty) {
      setState(() => _error = 'Ingresa el motivo o destino de la actividad.');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      final input = CrearSalidaVehicularInput(
        activoId: _selectedVehiculo!.id,
        empleadoId: _selectedConductor?.id,
        fecha: _fechaHoraFinal,
        descripcionActividad: actividad,
        observaciones: _observacionesController.text.trim().isEmpty
            ? null
            : _observacionesController.text.trim(),
      );

      await _service.registrar(input);

      if (!mounted) return;
      widget.onSalidaCreada?.call();
      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Salida vehicular registrada exitosamente'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF0F766E),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = 'Error al registrar salida: ${e.toString().replaceAll('Exception:', '')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.add_road_rounded,
                        color: Color(0xFF0284C7),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nueva Salida Vehicular',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Control de viajes, ruta y chofer asignado',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const Divider(height: 20),

                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Selección de Vehículo
                const Text(
                  'Vehículo a salir *',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _cargandoCatalogos ? null : _abrirSelectorVehiculo,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark ? Colors.white24 : Colors.black12,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    ),
                    child: _selectedVehiculo == null
                        ? Row(
                            children: [
                              const Icon(Icons.directions_car_rounded, color: Color(0xFF0284C7), size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _cargandoCatalogos ? 'Cargando vehículos...' : 'Seleccionar vehículo...',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.white54 : Colors.black45,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down_rounded),
                            ],
                          )
                        : Row(
                            children: [
                              VehiculoThumb(
                                urlImagen: _selectedVehiculo!.urlImagen,
                                size: 36,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedVehiculo!.displayVehiculoNombre,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        PlacaBadge(placa: _selectedVehiculo!.displayPlaca),
                                        const SizedBox(width: 6),
                                        TipoVehiculoBadge(tipo: _selectedVehiculo!.displayTipo),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.swap_horiz_rounded, size: 20),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 14),

                // Conductor Asignado
                const Text(
                  'Conductor responsable',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _cargandoCatalogos ? null : _abrirSelectorConductor,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark ? Colors.white24 : Colors.black12,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_pin_rounded, color: Color(0xFF0F766E), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedConductor?.nombreCompleto ?? 'Sin conductor asignado',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_selectedConductor?.cargo != null)
                                Text(
                                  _selectedConductor!.cargo!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down_rounded),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Fecha y Hora de salida
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Fecha de salida',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _seleccionarFecha,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                                borderRadius: BorderRadius.circular(12),
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_fecha.day.toString().padLeft(2, '0')}/${_fecha.month.toString().padLeft(2, '0')}/${_fecha.year}',
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hora de salida',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _seleccionarHora,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                                borderRadius: BorderRadius.circular(12),
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_hora.hour.toString().padLeft(2, '0')}:${_hora.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
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
                const SizedBox(height: 14),

                // Actividad / Destino
                SigmaTextField(
                  controller: _actividadController,
                  label: 'Descripción de la actividad / Destino *',
                  hint: 'Ej: Traslado de personal a Planta Corani para inspección técnica',
                  maxLines: 2,
                ),
                const SizedBox(height: 14),

                // Observaciones
                SigmaTextField(
                  controller: _observacionesController,
                  label: 'Observaciones (opcional)',
                  hint: 'Ej: Salida con vales de combustible autorizados',
                  maxLines: 2,
                ),
                const SizedBox(height: 20),

                // Botón Guardar
                SigmaPrimaryButton(
                  label: 'Registrar Salida Vehicular',
                  isLoading: _guardando,
                  onPressed: _guardando ? null : _guardar,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectorVehiculoSheet extends StatefulWidget {
  final List<ActivoOption> vehiculos;
  final String? selectedId;

  const _SelectorVehiculoSheet({required this.vehiculos, this.selectedId});

  @override
  State<_SelectorVehiculoSheet> createState() => _SelectorVehiculoSheetState();
}

class _SelectorVehiculoSheetState extends State<_SelectorVehiculoSheet> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = widget.vehiculos.where((v) {
      if (_filter.isEmpty) return true;
      final q = _filter.toLowerCase();
      return v.displayVehiculoNombre.toLowerCase().contains(q) ||
          v.displayPlaca.toLowerCase().contains(q) ||
          v.codigo.toLowerCase().contains(q);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Seleccionar Vehículo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: (val) => setState(() => _filter = val),
            decoration: InputDecoration(
              hintText: 'Buscar por placa, modelo o código...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No se encontraron vehículos'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final v = filtered[i];
                      final isSelected = v.id == widget.selectedId;
                      return ListTile(
                        onTap: () => Navigator.pop(context, v),
                        selected: isSelected,
                        leading: VehiculoThumb(urlImagen: v.urlImagen, size: 38),
                        title: Text(
                          v.displayVehiculoNombre,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        subtitle: Row(
                          children: [
                            PlacaBadge(placa: v.displayPlaca),
                            const SizedBox(width: 6),
                            TipoVehiculoBadge(tipo: v.displayTipo),
                          ],
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0284C7))
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SelectorConductorSheet extends StatefulWidget {
  final List<FuncionarioOption> conductores;
  final String? selectedId;

  const _SelectorConductorSheet({required this.conductores, this.selectedId});

  @override
  State<_SelectorConductorSheet> createState() => _SelectorConductorSheetState();
}

class _SelectorConductorSheetState extends State<_SelectorConductorSheet> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = widget.conductores.where((c) {
      if (_filter.isEmpty) return true;
      final q = _filter.toLowerCase();
      return c.nombreCompleto.toLowerCase().contains(q) ||
          c.codigo.toLowerCase().contains(q);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Seleccionar Conductor',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: (val) => setState(() => _filter = val),
            decoration: InputDecoration(
              hintText: 'Buscar conductor por nombre o código...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No se encontraron conductores'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final c = filtered[i];
                      final isSelected = c.id == widget.selectedId;
                      return ListTile(
                        onTap: () => Navigator.pop(context, c),
                        selected: isSelected,
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.15),
                          child: const Icon(Icons.person_rounded, color: Color(0xFF0F766E)),
                        ),
                        title: Text(
                          c.nombreCompleto,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        subtitle: Text(
                          c.cargo ?? c.codigo,
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0F766E))
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

