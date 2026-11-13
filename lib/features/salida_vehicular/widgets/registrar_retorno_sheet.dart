import 'package:flutter/material.dart';
import 'package:sigma_mobile/app/theme/app_theme.dart';
import 'package:sigma_mobile/core/services/location_service.dart';
import 'package:sigma_mobile/core/widgets/sigma_primary_button.dart';
import 'package:sigma_mobile/core/widgets/sigma_text_field.dart';
import 'package:sigma_mobile/features/salida_vehicular/models/salida_vehicular_models.dart';
import 'package:sigma_mobile/features/salida_vehicular/services/salida_vehicular_service.dart';

class RegistrarRetornoSheet extends StatefulWidget {
  final SalidaVehicular salida;
  final VoidCallback? onRetornoRegistrado;

  const RegistrarRetornoSheet({
    super.key,
    required this.salida,
    this.onRetornoRegistrado,
  });

  static Future<bool?> show(BuildContext context, SalidaVehicular salida) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RegistrarRetornoSheet(salida: salida),
    );
  }

  @override
  State<RegistrarRetornoSheet> createState() => _RegistrarRetornoSheetState();
}

class _RegistrarRetornoSheetState extends State<RegistrarRetornoSheet> {
  final _service = SalidaVehicularService.instance;
  final _kmController = TextEditingController();
  final _observacionController = TextEditingController();

  double? _latitud;
  double? _longitud;
  bool _obteniendoGps = false;
  bool _guardando = false;
  String? _error;
  String? _accionId;

  @override
  void initState() {
    super.initState();
    _buscarAccionFlowable();
    _obtenerGps();
  }

  @override
  void dispose() {
    _kmController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  Future<void> _buscarAccionFlowable() async {
    try {
      final acciones = await _service.obtenerAcciones(widget.salida.id);
      if (acciones != null && acciones.actions.isNotEmpty && mounted) {
        setState(() {
          _accionId = acciones.actions.first.name;
        });
      }
    } catch (_) {}
  }

  Future<void> _obtenerGps() async {
    setState(() => _obteniendoGps = true);
    try {
      final state = await LocationService.instance.checkStatus(fetchPosition: true);
      if (state.position != null && mounted) {
        setState(() {
          _latitud = state.position!.latitude;
          _longitud = state.position!.longitude;
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _obteniendoGps = false);
    }
  }

  Future<void> _guardarRetorno() async {
    final kmText = _kmController.text.trim();
    if (kmText.isEmpty) {
      setState(() => _error = 'Ingresa el kilometraje de llegada');
      return;
    }

    final km = double.tryParse(kmText.replaceAll(',', '.'));
    if (km == null || km < 0) {
      setState(() => _error = 'Ingresa un valor de kilometraje válido');
      return;
    }

    final kmInicial = widget.salida.kilometrajeInicial;
    if (kmInicial != null && km < kmInicial) {
      setState(() => _error = 'El kilometraje de llegada ($km) no puede ser menor al inicial ($kmInicial)');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      final input = EjecutarAccionSalidaInput(
        kilometraje: km,
        latitud: _latitud,
        longitud: _longitud,
        observacion: _observacionController.text.trim().isEmpty
            ? 'Retorno registrado desde app móvil'
            : _observacionController.text.trim(),
      );

      final accion = _accionId ?? 'registrarLlegada';
      await _service.ejecutarAccion(widget.salida.id, accion, input);

      if (!mounted) return;
      widget.onRetornoRegistrado?.call();
      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Llegada de vehículo registrada exitosamente'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF0F766E),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = 'Error al registrar retorno: ${e.toString().replaceAll('Exception:', '')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final kmInicial = widget.salida.kilometrajeInicial;

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 40),
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
                        color: const Color(0xFF0F766E).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF0F766E),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Registrar Llegada / Retorno',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Salida ${widget.salida.numero} · ${widget.salida.displayVehiculo}',
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

                // Indicador de odómetro inicial
                if (kmInicial != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.speed_rounded, size: 18, color: Color(0xFF0284C7)),
                        const SizedBox(width: 8),
                        Text(
                          'Kilometraje de salida registrado: ${kmInicial.toStringAsFixed(0)} km',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Input de Kilometraje Final
                SigmaTextField(
                  controller: _kmController,
                  label: 'Kilometraje de llegada (Odómetro) *',
                  hint: kmInicial != null ? 'Mayor a ${kmInicial.toStringAsFixed(0)}' : 'Ej: 145230',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.speed_rounded,
                ),
                const SizedBox(height: 14),

                // Coordenadas GPS
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _latitud != null ? Icons.location_on_rounded : Icons.location_off_rounded,
                        color: _latitud != null ? const Color(0xFF0F766E) : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _latitud != null
                              ? 'GPS: ${_latitud!.toStringAsFixed(5)}, ${_longitud!.toStringAsFixed(5)}'
                              : (_obteniendoGps ? 'Obteniendo GPS actual...' : 'Sin ubicación GPS'),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _obteniendoGps ? null : _obtenerGps,
                        icon: _obteniendoGps
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location_rounded, size: 16),
                        label: const Text('Actualizar', style: TextStyle(fontSize: 11)),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Observaciones
                SigmaTextField(
                  controller: _observacionController,
                  label: 'Observaciones de llegada',
                  hint: 'Ej: Llegada sin novedades, combustible restante 1/2 tanque',
                  maxLines: 2,
                ),
                const SizedBox(height: 20),

                // Botón Guardar Retorno
                SigmaPrimaryButton(
                  label: 'Confirmar Llegada de Vehículo',
                  isLoading: _guardando,
                  onPressed: _guardando ? null : _guardarRetorno,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

