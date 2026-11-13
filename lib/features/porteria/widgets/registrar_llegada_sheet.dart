import 'package:flutter/material.dart';
import 'package:sigma_mobile/app/theme/app_theme.dart';
import 'package:sigma_mobile/core/widgets/sigma_widgets.dart';
import 'package:sigma_mobile/features/porteria/models/porteria_models.dart';
import 'package:sigma_mobile/features/porteria/services/porteria_service.dart';
import 'package:sigma_mobile/features/porteria/widgets/vehiculo_display_widgets.dart';

class _ItemLlegadaDraft {
  final String itemId;
  final String? codigo;
  final String nombre;
  final String? placa;
  final String? tipo;
  final bool esCatalogado;
  final int cantidad;
  final String? observacionSalida;
  bool retornado;
  bool mostrarObservacion;
  final TextEditingController observacionController;

  _ItemLlegadaDraft({
    required this.itemId,
    required this.codigo,
    required this.nombre,
    this.placa,
    this.tipo,
    required this.esCatalogado,
    required this.cantidad,
    required this.observacionSalida,
  })  : retornado = true,
        mostrarObservacion = false,
        observacionController = TextEditingController();

  void dispose() {
    observacionController.dispose();
  }
}

Future<RegistroPorteria?> showRegistrarLlegadaPorteriaSheet(
  BuildContext context,
  RegistroPorteria registro,
) {
  return showModalBottomSheet<RegistroPorteria>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _RegistrarLlegadaSheet(registro: registro),
  );
}

class _RegistrarLlegadaSheet extends StatefulWidget {
  final RegistroPorteria registro;

  const _RegistrarLlegadaSheet({required this.registro});

  @override
  State<_RegistrarLlegadaSheet> createState() => _RegistrarLlegadaSheetState();
}

class _RegistrarLlegadaSheetState extends State<_RegistrarLlegadaSheet> {
  final _service = PorteriaService.instance;
  final _observacionGeneralCtrl = TextEditingController();

  late DateTime _fechaHoraLlegada;
  late List<_ItemLlegadaDraft> _items;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fechaHoraLlegada = DateTime.now();
    _items = widget.registro.activos
        .map(
          (a) => _ItemLlegadaDraft(
            itemId: a.id,
            codigo: a.activoCodigo,
            nombre: a.displayVehiculoNombre,
            placa: a.displayPlaca,
            tipo: a.displayTipo,
            esCatalogado: a.esCatalogado,
            cantidad: a.cantidad,
            observacionSalida: a.observacionSalida,
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _observacionGeneralCtrl.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  int get _duracionMinutos => _fechaHoraLlegada
      .difference(widget.registro.fechaHoraSalida)
      .inMinutes;

  bool get _fechaInvalida => _duracionMinutos < 0;

  int get _retornados => _items.where((i) => i.retornado).length;

  int get _pendientes => _items.length - _retornados;

  double get _progreso =>
      _items.isEmpty ? 1.0 : _retornados / _items.length;

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} · ${two(dt.hour)}:${two(dt.minute)}';
  }

  String _formatDuration(int totalMin) {
    if (totalMin < 1) return 'menos de 1 min';
    final d = totalMin ~/ 1440;
    final h = (totalMin % 1440) ~/ 60;
    final m = totalMin % 60;
    if (d > 0) return '${d}d ${h}h';
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '$m min';
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _fechaHoraLlegada,
      firstDate: widget.registro.fechaHoraSalida.subtract(
        const Duration(days: 1),
      ),
      lastDate: DateTime.now().add(const Duration(days: 2)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_fechaHoraLlegada),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _fechaHoraLlegada = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    if (_fechaInvalida) {
      setState(() {
        _errorMessage =
            'La hora de llegada no puede ser anterior a la hora de salida.';
      });
      return;
    }

    for (final item in _items) {
      if (!item.retornado &&
          item.observacionController.text.trim().isEmpty) {
        setState(() {
          item.mostrarObservacion = true;
          _errorMessage =
              'Indique el motivo por el que "${item.nombre}" no retornó.';
        });
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await _service.registrarLlegada(
        widget.registro.id,
        RegistrarLlegadaPorteriaInput(
          fechaHoraLlegada: _fechaHoraLlegada,
          observacionLlegada: _observacionGeneralCtrl.text.trim(),
          activos: _items
              .map(
                (i) => RegistroPorteriaActivoLlegadaInput(
                  itemId: i.itemId,
                  retornado: i.retornado,
                  observacionLlegada: i.observacionController.text.trim(),
                ),
              )
              .toList(),
        ),
      );

      if (!mounted) return;
      Navigator.pop(context, result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = PorteriaService.extractErrorMessage(e);
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppTheme.darkBackground : AppTheme.background;
    final cardBg = isDark ? AppTheme.darkSurface : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF172B4D);
    final subtitleColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    final registro = widget.registro;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabecera
            Container(
              padding: const EdgeInsets.fromLTRB(18, 10, 12, 14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: subtitleColor.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF10B981,
                          ).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.login_rounded,
                          color: Color(0xFF059669),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Registrar llegada',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: titleColor,
                              ),
                            ),
                            Text(
                              'Verifique el retorno del funcionario y activos (${registro.numero}).',
                              style: TextStyle(
                                fontSize: 12,
                                color: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, color: subtitleColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Contenido scrollable
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Resumen del registro
                    SigmaCard(
                      padding: const EdgeInsets.all(14),
                      borderRadius: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(
                                    0xFFF59E0B,
                                  ).withValues(alpha: 0.16),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _initials(registro.funcionarioDisplay),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Funcionario',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: subtitleColor,
                                      ),
                                    ),
                                    Text(
                                      registro.funcionarioDisplay,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        color: titleColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: subtitleColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  registro.numero,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: subtitleColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 18),
                          Wrap(
                            spacing: 14,
                            runSpacing: 6,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.logout_rounded,
                                    size: 14,
                                    color: Color(0xFFD97706),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Salida: ${_formatDateTime(registro.fechaHoraSalida)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: titleColor,
                                    ),
                                  ),
                                ],
                              ),
                              if (registro.guardiaSalidaNombre != null &&
                                  registro.guardiaSalidaNombre!.isNotEmpty)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified_user_outlined,
                                      size: 14,
                                      color: subtitleColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      registro.guardiaSalidaNombre!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: subtitleColor,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          if (registro.observacionSalida != null &&
                              registro.observacionSalida!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Motivo: ${registro.observacionSalida}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: subtitleColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Hora de llegada
                    Row(
                      children: [
                        Expanded(
                          child: SigmaCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            borderRadius: 12,
                            onTap: _pickDateTime,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 18,
                                  color: _fechaInvalida
                                      ? Colors.red.shade600
                                      : const Color(0xFF059669),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hora de llegada *',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: subtitleColor,
                                        ),
                                      ),
                                      Text(
                                        _formatDateTime(_fechaHoraLlegada),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: titleColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.edit_calendar_rounded,
                                  size: 17,
                                  color: subtitleColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _fechaHoraLlegada = DateTime.now();
                              _errorMessage = null;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Ahora',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          _fechaInvalida
                              ? Icons.warning_amber_rounded
                              : Icons.timer_outlined,
                          size: 14,
                          color: _fechaInvalida
                              ? Colors.red.shade600
                              : subtitleColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _fechaInvalida
                              ? 'La llegada es anterior a la salida.'
                              : 'Tiempo fuera: ${_formatDuration(_duracionMinutos)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _fechaInvalida
                                ? Colors.red.shade600
                                : subtitleColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Verificación de vehículos
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.directions_car_rounded,
                              size: 17,
                              color: Color(0xFF0284C7),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Verificación de vehículos',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: titleColor,
                              ),
                            ),
                          ],
                        ),
                        if (_items.length > 1)
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () {
                              setState(() {
                                for (final item in _items) {
                                  item.retornado = true;
                                }
                              });
                            },
                            icon: const Icon(Icons.done_all_rounded, size: 16),
                            label: const Text(
                              'Todos retornaron',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    if (_items.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$_retornados de ${_items.length} retornado(s)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: subtitleColor,
                            ),
                          ),
                          if (_pendientes > 0)
                            Text(
                              '$_pendientes sin retornar',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.red.shade600,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _progreso,
                          minHeight: 6,
                          backgroundColor: subtitleColor.withValues(alpha: 0.18),
                          color: _pendientes > 0
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(height: 12),

                      ..._items.map((item) {
                        final mostrarObs =
                            item.mostrarObservacion || !item.retornado;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: item.retornado
                                    ? const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.4)
                                    : Colors.red.withValues(alpha: 0.5),
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const VehiculoThumb(size: 36),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.cantidad > 1
                                                ? '${item.nombre} (×${item.cantidad})'
                                                : item.nombre,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: titleColor,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Wrap(
                                            spacing: 4,
                                            runSpacing: 2,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              if (item.tipo != null)
                                                TipoVehiculoBadge(
                                                  tipo: item.tipo!,
                                                  compact: true,
                                                ),
                                              if (item.placa != null &&
                                                  item.placa!.isNotEmpty)
                                                PlacaBadge(
                                                  placa: item.placa!,
                                                  compact: true,
                                                ),
                                              if (item.observacionSalida !=
                                                      null &&
                                                  item.observacionSalida!
                                                      .isNotEmpty)
                                                Text(
                                                  '· ${item.observacionSalida!}',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: subtitleColor,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _RetornoOptionButton(
                                        active: item.retornado,
                                        activeColor: const Color(0xFF059669),
                                        icon: Icons.check_circle_rounded,
                                        label: 'Retornó',
                                        onTap: () => setState(
                                          () => item.retornado = true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _RetornoOptionButton(
                                        active: !item.retornado,
                                        activeColor: Colors.red.shade600,
                                        icon: Icons.cancel_rounded,
                                        label: 'No retornó',
                                        onTap: () => setState(
                                          () => item.retornado = false,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (mostrarObs)
                                  SigmaTextField(
                                    controller: item.observacionController,
                                    label: item.retornado
                                        ? 'Observación (estado, daños...)'
                                        : 'Motivo por el que no retornó *',
                                    hint: item.retornado
                                        ? 'Opcional'
                                        : 'Obligatorio cuando no retorna',
                                  )
                                else
                                  InkWell(
                                    onTap: () => setState(
                                      () => item.mostrarObservacion = true,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.add_comment_outlined,
                                            size: 14,
                                            color: subtitleColor,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            'Agregar observación',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: subtitleColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),

                      if (_pendientes > 0)
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFF59E0B,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(
                                0xFFF59E0B,
                              ).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 18,
                                color: Color(0xFFD97706),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _pendientes == 1
                                      ? '1 activo quedará registrado como no retornado. Indique el motivo.'
                                      : '$_pendientes activos quedarán registrados como no retornados. Indique el motivo en cada uno.',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],

                    const SizedBox(height: 16),

                    SigmaTextField(
                      controller: _observacionGeneralCtrl,
                      label: 'Observación general de llegada',
                      hint: 'Novedades al retorno...',
                      prefixIcon: Icons.notes_rounded,
                      maxLines: 2,
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 18,
                              color: Colors.red.shade600,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 4,
                    child: SigmaPrimaryButton(
                      label: 'Registrar llegada',
                      loadingLabel: 'Registrando...',
                      icon: Icons.login_rounded,
                      isLoading: _isSubmitting,
                      onPressed: !_fechaInvalida ? _submit : null,
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

class _RetornoOptionButton extends StatelessWidget {
  final bool active;
  final Color activeColor;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RetornoOptionButton({
    required this.active,
    required this.activeColor,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: active
              ? activeColor
              : (isDark ? const Color(0xFF0E1729) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: active ? Colors.white : inactiveColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

