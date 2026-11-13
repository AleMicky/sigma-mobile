import 'package:flutter/material.dart';
import 'package:sigma_mobile/app/theme/app_theme.dart';
import 'package:sigma_mobile/core/widgets/sigma_widgets.dart';
import 'package:sigma_mobile/features/solicitud_vehicular/models/solicitud_vehicular_models.dart';
import 'package:sigma_mobile/features/solicitud_vehicular/services/solicitud_vehicular_service.dart';

class SolicitudDetalleSheet extends StatefulWidget {
  final SolicitudVehicular solicitud;
  final VoidCallback onUpdated;

  const SolicitudDetalleSheet({
    super.key,
    required this.solicitud,
    required this.onUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required SolicitudVehicular solicitud,
    required VoidCallback onUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SolicitudDetalleSheet(
        solicitud: solicitud,
        onUpdated: onUpdated,
      ),
    );
  }

  @override
  State<SolicitudDetalleSheet> createState() => _SolicitudDetalleSheetState();
}

class _SolicitudDetalleSheetState extends State<SolicitudDetalleSheet> {
  final _service = SolicitudVehicularService.instance;
  bool _isDeleting = false;

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y  $h:$min';
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Cancelar Solicitud'),
          content: Text(
            '¿Deseas eliminar la solicitud ${widget.solicitud.numero}? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Volver'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      await _service.eliminar(widget.solicitud.id);
      widget.onUpdated();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Solicitud ${widget.solicitud.numero} eliminada'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(SolicitudVehicularService.extractErrorMessage(e)),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sol = widget.solicitud;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final estado = sol.estado;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pestaña deslizable
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
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: estado.color.withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: estado.color.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(estado.icon, size: 14, color: estado.color),
                        const SizedBox(width: 4),
                        Text(
                          estado.label.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: estado.color,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      sol.numero,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
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

            // Contenido deslizable
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. Destino e Itinerario
                  SigmaCard(
                    padding: const EdgeInsets.all(14),
                    borderRadius: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.map_rounded, size: 16, color: Color(0xFF0284C7)),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Destino e Itinerario',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.people_alt_outlined, size: 13),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${sol.cantidadPasajeros} ${sol.cantidadPasajeros == 1 ? "pasajero" : "pasajeros"}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          sol.destino,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),

                        // Fila de Fechas
                        Row(
                          children: [
                            Expanded(
                              child: _buildTimeItem(
                                label: 'SALIDA PROGRAMADA',
                                value: _formatDateTime(sol.fechaSalida),
                                icon: Icons.flight_takeoff_rounded,
                                iconColor: const Color(0xFF0284C7),
                              ),
                            ),
                            Expanded(
                              child: _buildTimeItem(
                                label: 'RETORNO ESTIMADO',
                                value: _formatDateTime(sol.fechaRetornoEstimada),
                                icon: Icons.flight_land_rounded,
                                iconColor: const Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: isDark ? 0.2 : 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timelapse_rounded, size: 14, color: Color(0xFF0284C7)),
                              const SizedBox(width: 6),
                              Text(
                                'Duración estimada: ${sol.duracionCalculada}',
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Clasificación y Solicitante
                  SigmaCard(
                    padding: const EdgeInsets.all(14),
                    borderRadius: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Clasificación y Personal',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        _buildDetailRow(
                          label: 'Tipo de Solicitud',
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            children: [
                              Text(
                                sol.tipoSolicitud?.nombre ?? 'General',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                              ),
                              if (sol.tipoSolicitud?.esEmergencia == true)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'EMERGENCIA',
                                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          label: 'Funcionario Solicitante',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sol.solicitante?.nombreCompleto ?? 'Solicitante no especificado',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                              ),
                              if (sol.solicitante?.subtitulo.isNotEmpty == true)
                                Text(
                                  sol.solicitante!.subtitulo,
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Vehículo y Conductor (Si ya está asignado)
                  if (sol.conductorAsignado != null || sol.activoPlaca != null) ...[
                    SigmaCard(
                      padding: const EdgeInsets.all(14),
                      borderRadius: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.directions_car_rounded, size: 16, color: Colors.green.shade700),
                              const SizedBox(width: 6),
                              const Text(
                                'Asignación Vehicular',
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (sol.activoPlaca != null)
                            _buildDetailRow(
                              label: 'Vehículo Asignado',
                              child: Text(
                                '${sol.activoPlaca} ${sol.activoModelo != null ? "· ${sol.activoModelo}" : ""}',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                              ),
                            ),
                          if (sol.conductorAsignado != null) ...[
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              label: 'Conductor Asignado',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sol.conductorAsignado?.nombreCompleto ?? 'Conductor asignado',
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                                  ),
                                  if (sol.conductorAsignado?.numeroLicencia != null)
                                    Text(
                                      'Licencia: ${sol.conductorAsignado?.numeroLicencia} (Cat. ${sol.conductorAsignado?.categoriaLicencia ?? "-"})',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 4. Motivo y Justificación
                  SigmaCard(
                    padding: const EdgeInsets.all(14),
                    borderRadius: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Motivo y Justificación',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'ASUNTO O MOTIVO:',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sol.motivo,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                        if (sol.justificacion != null && sol.justificacion!.trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Text(
                            'JUSTIFICACIÓN OPERATIVA:',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sol.justificacion!,
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ],
                        if (sol.observacion != null && sol.observacion!.trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Text(
                            'OBSERVACIONES:',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sol.observacion!,
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Acciones inferiores
            if (sol.puedeEliminar) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                      side: BorderSide(color: Colors.red.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isDeleting ? null : _confirmDelete,
                    icon: _isDeleting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline_rounded, size: 18),
                    label: Text(
                      _isDeleting ? 'Cancelando...' : 'Cancelar Solicitud',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeItem({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildDetailRow({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        child,
      ],
    );
  }
}

