import 'package:flutter/material.dart';
import 'package:sigma_mobile/app/theme/app_theme.dart';
import 'package:sigma_mobile/core/widgets/sigma_card.dart';
import 'package:sigma_mobile/core/widgets/sigma_primary_button.dart';
import 'package:sigma_mobile/features/porteria/widgets/vehiculo_display_widgets.dart';
import 'package:sigma_mobile/features/salida_vehicular/models/salida_vehicular_models.dart';
import 'package:sigma_mobile/features/salida_vehicular/services/salida_vehicular_service.dart';
import 'package:sigma_mobile/features/salida_vehicular/widgets/registrar_bitacora_sheet.dart';
import 'package:sigma_mobile/features/salida_vehicular/widgets/registrar_retorno_sheet.dart';

class DetalleSalidaSheet extends StatefulWidget {
  final SalidaVehicular salida;
  final VoidCallback? onActualizado;

  const DetalleSalidaSheet({
    super.key,
    required this.salida,
    this.onActualizado,
  });

  static Future<void> show(
    BuildContext context,
    SalidaVehicular salida, {
    VoidCallback? onActualizado,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DetalleSalidaSheet(
        salida: salida,
        onActualizado: onActualizado,
      ),
    );
  }

  @override
  State<DetalleSalidaSheet> createState() => _DetalleSalidaSheetState();
}

class _DetalleSalidaSheetState extends State<DetalleSalidaSheet> {
  final _service = SalidaVehicularService.instance;
  late SalidaVehicular _salida;
  bool _recargando = false;
  bool _cancelando = false;

  @override
  void initState() {
    super.initState();
    _salida = widget.salida;
    _recargarDetalle();
  }

  Future<void> _recargarDetalle() async {
    setState(() => _recargando = true);
    try {
      final updated = await _service.obtenerPorId(_salida.id);
      if (mounted) {
        setState(() {
          _salida = updated;
          _recargando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _recargando = false);
    }
  }

  Future<void> _confirmarCancelacion() async {
    final motivoController = TextEditingController();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Cancelar Salida Vehicular', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Estás seguro de cancelar esta salida vehicular?',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: motivoController,
              decoration: const InputDecoration(
                labelText: 'Motivo de cancelación (opcional)',
                hintText: 'Ej: Comisión suspendida por lluvia...',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );

    if (confirmado == true && mounted) {
      setState(() => _cancelando = true);
      try {
        await _service.cancelar(_salida.id, motivo: motivoController.text.trim());
        if (!mounted) return;
        widget.onActualizado?.call();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Salida vehicular cancelada'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _cancelando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cancelar: ${e.toString().replaceAll('Exception:', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _abrirRegistrarRetorno() async {
    final ok = await RegistrarRetornoSheet.show(context, _salida);
    if (ok == true && mounted) {
      widget.onActualizado?.call();
      _recargarDetalle();
    }
  }

  Future<void> _abrirRegistrarBitacora() async {
    final ok = await RegistrarBitacoraSheet.show(context, _salida);
    if (ok == true && mounted) {
      widget.onActualizado?.call();
      _recargarDetalle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
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
            const SizedBox(height: 8),

            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _salida.estadoColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _salida.estadoColor.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      _salida.estadoLabel,
                      style: TextStyle(
                        color: _salida.estadoColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (_recargando)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      onPressed: _recargarDetalle,
                      tooltip: 'Actualizar',
                      visualDensity: VisualDensity.compact,
                    ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const Divider(height: 10),

            // Content Body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Correlativo y Fecha
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _salida.numero.isNotEmpty ? _salida.numero : 'SALIDA VEHICULAR',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Fecha: ${_salida.fecha.day.toString().padLeft(2, '0')}/${_salida.fecha.month.toString().padLeft(2, '0')}/${_salida.fecha.year} ${_salida.fecha.hour.toString().padLeft(2, '0')}:${_salida.fecha.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PlacaBadge(placa: _salida.displayPlaca),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Tarjeta Vehículo
                  SigmaCard(
                    padding: const EdgeInsets.all(12),
                    borderRadius: 14,
                    child: Row(
                      children: [
                        const VehiculoThumb(size: 44),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _salida.displayVehiculo,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  PlacaBadge(placa: _salida.displayPlaca),
                                  const SizedBox(width: 6),
                                  TipoVehiculoBadge(
                                    tipo: _salida.marca != null && _salida.marca!.isNotEmpty
                                        ? '${_salida.marca} ${_salida.modelo ?? ''}'
                                        : 'Vehículo Oficial',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Tarjeta Conductor
                  SigmaCard(
                    padding: const EdgeInsets.all(12),
                    borderRadius: 14,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.15),
                          child: const Icon(Icons.person_rounded, size: 20, color: Color(0xFF0F766E)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Conductor Asignado',
                                style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                _salida.displayConductor,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Actividad y Destino
                  const Text(
                    'Actividad / Destino',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                    ),
                    child: Text(
                      _salida.descripcionActividad.isNotEmpty
                          ? _salida.descripcionActividad
                          : 'Sin descripción registrada',
                      style: const TextStyle(fontSize: 13, height: 1.3),
                    ),
                  ),

                  if (_salida.observaciones != null && _salida.observaciones!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Observaciones',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                      ),
                      child: Text(
                        _salida.observaciones!,
                        style: const TextStyle(fontSize: 12.5, color: Colors.grey),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Eventos de Kilometraje / Trayecto
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Registro de Kilometraje y Eventos',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                      if (_salida.recorridoKm != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F766E).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Recorrido: ${_salida.recorridoKm!.toStringAsFixed(0)} km',
                            style: const TextStyle(
                              color: Color(0xFF0F766E),
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_salida.eventos.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                      ),
                      child: const Center(
                        child: Text(
                          'No hay eventos de odómetro registrados todavía.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _salida.eventos.map((e) {
                        final isSalidaEv = e.tipoEvento.toUpperCase().contains('SALIDA');
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSalidaEv ? Icons.flight_takeoff_rounded : Icons.flight_land_rounded,
                                color: isSalidaEv ? const Color(0xFF0284C7) : const Color(0xFF0F766E),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.tipoEvento,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      '${e.fechaHora.day.toString().padLeft(2, '0')}/${e.fechaHora.month.toString().padLeft(2, '0')} ${e.fechaHora.hour.toString().padLeft(2, '0')}:${e.fechaHora.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              if (e.kilometraje != null)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${e.kilometraje!.toStringAsFixed(0)} km',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                                    ),
                                    if (e.latitud != null)
                                      const Text(
                                        'Con GPS',
                                        style: TextStyle(fontSize: 10, color: Color(0xFF0F766E)),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 16),

                  // Sección Bitácoras
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bitácora de Ruta / Incidentes',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                      if (_salida.isEnRuta)
                        TextButton.icon(
                          onPressed: _abrirRegistrarBitacora,
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Registrar', style: TextStyle(fontSize: 11.5)),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  if (_salida.bitacoras.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                      ),
                      child: const Center(
                        child: Text(
                          'Sin novedades o incidentes reportados en ruta.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _salida.bitacoras.map((b) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(b.tipoIcon, size: 18, color: b.tipoColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          b.tipo,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: b.tipoColor,
                                          ),
                                        ),
                                        Text(
                                          '${b.fechaHora.day.toString().padLeft(2, '0')}/${b.fechaHora.month.toString().padLeft(2, '0')} ${b.fechaHora.hour.toString().padLeft(2, '0')}:${b.fechaHora.minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      b.descripcion,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Bottom Actions (si está en ruta)
            if (_salida.isEnRuta)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Cancelar Salida',
                      icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                      onPressed: _cancelando ? null : _confirmarCancelacion,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SigmaPrimaryButton(
                        label: 'Registrar Llegada',
                        icon: Icons.check_circle_rounded,
                        onPressed: _abrirRegistrarRetorno,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

