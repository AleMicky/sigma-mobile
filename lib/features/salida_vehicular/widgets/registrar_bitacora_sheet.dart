import 'package:flutter/material.dart';
import 'package:sigma_mobile/app/theme/app_theme.dart';
import 'package:sigma_mobile/core/services/location_service.dart';
import 'package:sigma_mobile/core/widgets/sigma_primary_button.dart';
import 'package:sigma_mobile/core/widgets/sigma_text_field.dart';
import 'package:sigma_mobile/features/salida_vehicular/models/salida_vehicular_models.dart';
import 'package:sigma_mobile/features/salida_vehicular/services/salida_vehicular_service.dart';

class RegistrarBitacoraSheet extends StatefulWidget {
  final SalidaVehicular salida;
  final VoidCallback? onBitacoraRegistrada;

  const RegistrarBitacoraSheet({
    super.key,
    required this.salida,
    this.onBitacoraRegistrada,
  });

  static Future<bool?> show(BuildContext context, SalidaVehicular salida) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RegistrarBitacoraSheet(salida: salida),
    );
  }

  @override
  State<RegistrarBitacoraSheet> createState() => _RegistrarBitacoraSheetState();
}

class _RegistrarBitacoraSheetState extends State<RegistrarBitacoraSheet> {
  final _service = SalidaVehicularService.instance;
  final _descController = TextEditingController();

  String _tipo = 'ACTIVIDAD'; // ACTIVIDAD | NOVEDAD | INCIDENTE
  double? _latitud;
  double? _longitud;
  bool _obteniendoGps = false;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _obtenerGps();
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
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

  Future<void> _guardar() async {
    final desc = _descController.text.trim();
    if (desc.isEmpty) {
      setState(() => _error = 'Ingresa la descripción de la bitácora o novedad.');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      final input = RegistrarBitacoraInput(
        tipo: _tipo,
        descripcion: desc,
        fechaHora: DateTime.now(),
        latitud: _latitud,
        longitud: _longitud,
      );

      await _service.registrarBitacora(widget.salida.id, input);

      if (!mounted) return;
      widget.onBitacoraRegistrada?.call();
      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bitácora ($_tipo) registrada correctamente'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF0F766E),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = 'Error al registrar bitácora: ${e.toString().replaceAll('Exception:', '')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        color: Colors.amber,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Registrar en Bitácora',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Salida ${widget.salida.numero} · Registro en ruta',
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
                          child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Selección de Tipo de Bitácora
                const Text(
                  'Tipo de registro',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildTipoChip('ACTIVIDAD', Icons.assignment_outlined, const Color(0xFF0284C7)),
                    const SizedBox(width: 8),
                    _buildTipoChip('NOVEDAD', Icons.info_outline_rounded, Colors.amber.shade800),
                    const SizedBox(width: 8),
                    _buildTipoChip('INCIDENTE', Icons.warning_rounded, Colors.red.shade700),
                  ],
                ),
                const SizedBox(height: 16),

                // Descripción
                SigmaTextField(
                  controller: _descController,
                  label: 'Descripción de lo ocurrido *',
                  hint: _tipo == 'INCIDENTE'
                      ? 'Ej: Se reporta pinchazo de llanta delantera en km 45, cambio por auxilio...'
                      : _tipo == 'NOVEDAD'
                          ? 'Ej: Desvío temporal por mantenimiento de camino...'
                          : 'Ej: Llegada a punto de control intermedio...',
                  maxLines: 3,
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
                const SizedBox(height: 20),

                // Botón Guardar
                SigmaPrimaryButton(
                  label: 'Guardar Registro en Bitácora',
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

  Widget _buildTipoChip(String tipo, IconData icon, Color color) {
    final isSelected = _tipo == tipo;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tipo = tipo),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
            border: Border.all(
              color: isSelected ? color : Colors.grey.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? color : Colors.grey),
              const SizedBox(height: 4),
              Text(
                tipo,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? color : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

