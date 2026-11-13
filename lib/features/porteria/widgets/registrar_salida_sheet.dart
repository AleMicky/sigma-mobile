import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sigma_mobile/app/theme/app_theme.dart';
import 'package:sigma_mobile/core/widgets/sigma_widgets.dart';
import 'package:sigma_mobile/features/porteria/models/porteria_models.dart';
import 'package:sigma_mobile/features/porteria/services/porteria_service.dart';
import 'package:sigma_mobile/features/porteria/widgets/vehiculo_display_widgets.dart';

enum _ItemModo { vehiculo, libre }

class _ActivoRowDraft {
  _ItemModo modo;
  ActivoOption? activo;
  final TextEditingController descripcionController;
  final TextEditingController observacionController;
  int cantidad;
  bool mostrarObservacion;

  _ActivoRowDraft({
    this.modo = _ItemModo.vehiculo,
    String descripcion = '',
  })  : cantidad = 1,
        mostrarObservacion = false,
        descripcionController = TextEditingController(text: descripcion),
        observacionController = TextEditingController();

  bool get esValido => modo == _ItemModo.vehiculo
      ? activo != null
      : descripcionController.text.trim().isNotEmpty;

  void dispose() {
    descripcionController.dispose();
    observacionController.dispose();
  }
}

Future<RegistroPorteria?> showRegistrarSalidaPorteriaSheet(
  BuildContext context,
) {
  return showModalBottomSheet<RegistroPorteria>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _RegistrarSalidaSheet(),
  );
}

class _RegistrarSalidaSheet extends StatefulWidget {
  const _RegistrarSalidaSheet();

  @override
  State<_RegistrarSalidaSheet> createState() => _RegistrarSalidaSheetState();
}

class _RegistrarSalidaSheetState extends State<_RegistrarSalidaSheet> {
  final _service = PorteriaService.instance;
  final _observacionGeneralCtrl = TextEditingController();
  final _personaExternaCtrl = TextEditingController();
  final _placaExternaCtrl = TextEditingController();

  bool _esExterno = false;
  FuncionarioOption? _funcionario;
  DateTime _fechaHoraSalida = DateTime.now();
  final _ActivoRowDraft _item = _ActivoRowDraft();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _observacionGeneralCtrl.dispose();
    _personaExternaCtrl.dispose();
    _placaExternaCtrl.dispose();
    _item.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_esExterno) {
      return _personaExternaCtrl.text.trim().isNotEmpty &&
          _placaExternaCtrl.text.trim().isNotEmpty;
    }
    return _funcionario != null && _item.esValido;
  }

  Future<void> _pickFuncionario() async {
    final selected = await showModalBottomSheet<FuncionarioOption>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FuncionarioPickerSheet(selected: _funcionario),
    );
    if (selected != null && mounted) {
      setState(() {
        _funcionario = selected;
        _errorMessage = null;
      });
    }
  }

  Future<void> _pickActivo(_ActivoRowDraft row) async {
    final selected = await showModalBottomSheet<ActivoOption>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ActivoPickerSheet(selected: row.activo),
    );
    if (selected != null && mounted) {
      setState(() {
        row.activo = selected;
        _errorMessage = null;
      });
    }
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _fechaHoraSalida,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_fechaHoraSalida),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _fechaHoraSalida = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    if (!_esExterno) {
      if (_funcionario == null) {
        setState(
          () => _errorMessage = 'Debe seleccionar el funcionario que sale.',
        );
        return;
      }
      if (!_item.esValido) {
        setState(
          () => _errorMessage =
              'Debe seleccionar un vehículo o ingresar su descripción.',
        );
        return;
      }
    } else {
      if (_personaExternaCtrl.text.trim().isEmpty) {
        setState(
          () => _errorMessage =
              'Debe ingresar el nombre de la persona externa.',
        );
        return;
      }
      if (_placaExternaCtrl.text.trim().isEmpty) {
        setState(
          () => _errorMessage =
              'Debe ingresar la placa del vehículo externo.',
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final input = _esExterno
          ? RegistrarSalidaPorteriaInput(
              esExterno: true,
              personaExterna: _personaExternaCtrl.text.trim(),
              placaExterna: _placaExternaCtrl.text.trim().toUpperCase(),
              fechaHoraSalida: _fechaHoraSalida,
              observacionSalida: _observacionGeneralCtrl.text.trim(),
              activos: [
                RegistroPorteriaActivoSalidaInput(
                  descripcionItem:
                      'Vehículo externo - Placa: ${_placaExternaCtrl.text.trim().toUpperCase()}',
                  cantidad: 1,
                ),
              ],
            )
          : RegistrarSalidaPorteriaInput(
              esExterno: false,
              empleadoId: _funcionario!.id,
              fechaHoraSalida: _fechaHoraSalida,
              observacionSalida: _observacionGeneralCtrl.text.trim(),
              activos: [
                RegistroPorteriaActivoSalidaInput(
                  activoId: _item.modo == _ItemModo.vehiculo
                      ? _item.activo?.id
                      : null,
                  descripcionItem: _item.modo == _ItemModo.libre
                      ? _item.descripcionController.text.trim()
                      : null,
                  cantidad: 1,
                  observacionSalida:
                      _item.observacionController.text.trim().isNotEmpty
                          ? _item.observacionController.text.trim()
                          : null,
                ),
              ],
            );

      final result = await _service.registrarSalida(input);

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

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} · ${two(dt.hour)}:${two(dt.minute)}';
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
            // Handle y cabecera
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
                          color: AppTheme.secondary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: AppTheme.secondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Registrar salida en portería',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: titleColor,
                              ),
                            ),
                            Text(
                              _esExterno
                                  ? 'Control de salida de personas y vehículos externos.'
                                  : 'Control de salida de funcionarios y vehículos institucionales.',
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
                    // Segmento Interno / Externo
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0E1729)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                if (_esExterno) {
                                  setState(() {
                                    _esExterno = false;
                                    _errorMessage = null;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: !_esExterno
                                      ? (isDark
                                          ? AppTheme.darkSurface
                                          : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: !_esExterno
                                      ? [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.badge_outlined,
                                      size: 16,
                                      color: !_esExterno
                                          ? AppTheme.primary
                                          : subtitleColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Interno (Mina)',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: !_esExterno
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: !_esExterno
                                            ? titleColor
                                            : subtitleColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                if (!_esExterno) {
                                  setState(() {
                                    _esExterno = true;
                                    _errorMessage = null;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: _esExterno
                                      ? (isDark
                                          ? AppTheme.darkSurface
                                          : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: _esExterno
                                      ? [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.business_rounded,
                                      size: 16,
                                      color: _esExterno
                                          ? Colors.purple
                                          : subtitleColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Externo / Visita',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: _esExterno
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: _esExterno
                                            ? titleColor
                                            : subtitleColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Paso 1: ¿Quién sale?
                    _StepHeader(
                      step: 1,
                      title: _esExterno
                          ? '¿Quién sale? (Persona externa)'
                          : '¿Quién sale? (Funcionario)',
                      subtitle: _esExterno
                          ? 'Nombre de la visita o conductor externo.'
                          : 'Funcionario y hora de salida.',
                    ),
                    const SizedBox(height: 10),

                    if (!_esExterno)
                      SigmaCard(
                        padding: const EdgeInsets.all(12),
                        borderRadius: 14,
                        onTap: _pickFuncionario,
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _funcionario != null
                                    ? AppTheme.secondary.withValues(alpha: 0.14)
                                    : subtitleColor.withValues(alpha: 0.12),
                              ),
                              child: Icon(
                                Icons.person_rounded,
                                size: 20,
                                color: _funcionario != null
                                    ? AppTheme.secondary
                                    : subtitleColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _funcionario == null
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Seleccionar funcionario *',
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: titleColor,
                                          ),
                                        ),
                                        Text(
                                          'Toque para buscar por nombre o código',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: subtitleColor,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                _funcionario!.nombreCompleto,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: titleColor,
                                                ),
                                              ),
                                            ),
                                            if (_funcionario!.codigo.isNotEmpty) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 1.5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: subtitleColor
                                                      .withValues(alpha: 0.14),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  _funcionario!.codigo,
                                                  style: TextStyle(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: subtitleColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (_funcionario!.subtitle.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            _funcionario!.subtitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: subtitleColor,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: subtitleColor,
                            ),
                          ],
                        ),
                      )
                    else
                      SigmaTextField(
                        controller: _personaExternaCtrl,
                        label: 'Nombre completo de la persona externa *',
                        hint: 'Ej. Juan Carlos Pérez - Proveedor / Contratista',
                        prefixIcon: Icons.person_outline_rounded,
                        onChanged: (_) => setState(() {}),
                      ),

                    const SizedBox(height: 10),
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
                                  color: isDark
                                      ? AppTheme.accentGold
                                      : AppTheme.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hora de salida',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: subtitleColor,
                                        ),
                                      ),
                                      Text(
                                        _formatDateTime(_fechaHoraSalida),
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
                            setState(() => _fechaHoraSalida = DateTime.now());
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

                    const SizedBox(height: 20),

                    // Paso 2: ¿Qué vehículo retira?
                    _StepHeader(
                      step: 2,
                      title: _esExterno
                          ? 'Vehículo externo'
                          : '¿Qué vehículo retira?',
                      subtitle: _esExterno
                          ? 'Placa del vehículo externo.'
                          : 'Vehículo institucional del catálogo o ítem libre.',
                    ),
                    const SizedBox(height: 10),

                    if (!_esExterno)
                      _buildItemRow(
                        row: _item,
                        valido: _item.esValido,
                        isDark: isDark,
                        titleColor: titleColor,
                        subtitleColor: subtitleColor,
                      )
                    else
                      SigmaTextField(
                        controller: _placaExternaCtrl,
                        label: 'Placa del vehículo externo *',
                        hint: 'Ej. 4021-XPT',
                        prefixIcon: Icons.directions_car_outlined,
                        textCapitalization: TextCapitalization.characters,
                        onChanged: (_) => setState(() {}),
                      ),

                    const SizedBox(height: 20),

                    // Paso 3: Observaciones
                    const _StepHeader(
                      step: 3,
                      title: 'Observaciones',
                      subtitle: 'Opcional. Motivo de la salida o detalle adicional.',
                    ),
                    const SizedBox(height: 10),
                    SigmaTextField(
                      controller: _observacionGeneralCtrl,
                      label: 'Observación general de salida',
                      hint: 'Ej. Comisión de servicio a oficina regional...',
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

            // Footer fijo
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
                      label: _esExterno
                          ? 'Registrar salida (Externo)'
                          : 'Registrar salida (Interno)',
                      loadingLabel: 'Registrando...',
                      icon: Icons.logout_rounded,
                      isLoading: _isSubmitting,
                      onPressed: _canSubmit ? _submit : null,
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

  Widget _buildItemRow({
    required _ActivoRowDraft row,
    required bool valido,
    required bool isDark,
    required Color titleColor,
    required Color subtitleColor,
  }) {
    final borderColor = valido
        ? const Color(0xFF10B981).withValues(alpha: 0.45)
        : (isDark
              ? Colors.white.withValues(alpha: 0.09)
              : const Color(0xFFE2E8F0));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: valido
                      ? const Color(0xFF10B981).withValues(alpha: 0.16)
                      : subtitleColor.withValues(alpha: 0.14),
                ),
                alignment: Alignment.center,
                child: valido
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Color(0xFF059669),
                      )
                    : Icon(
                        Icons.directions_car_rounded,
                        size: 14,
                        color: subtitleColor,
                      ),
              ),
              const SizedBox(width: 8),
              // Selector modo
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0E1729)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ModeTabButton(
                          active: row.modo == _ItemModo.vehiculo,
                          icon: Icons.directions_car_rounded,
                          label: 'Vehículo',
                          onTap: () {
                            setState(() {
                              row.modo = _ItemModo.vehiculo;
                              row.descripcionController.clear();
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: _ModeTabButton(
                          active: row.modo == _ItemModo.libre,
                          icon: Icons.edit_note_rounded,
                          label: 'Ítem libre',
                          onTap: () {
                            setState(() {
                              row.modo = _ItemModo.libre;
                              row.activo = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (row.modo == _ItemModo.vehiculo)
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _pickActivo(row),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0E1729)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF26354D)
                        : const Color(0xFFD8E1EC),
                  ),
                ),
                child: row.activo != null
                    ? Row(
                        children: [
                          VehiculoThumb(
                            urlImagen: row.activo!.urlImagen,
                            size: 38,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  row.activo!.displayVehiculoNombre,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
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
                                    TipoVehiculoBadge(
                                      tipo: row.activo!.displayTipo,
                                      compact: true,
                                    ),
                                    PlacaBadge(
                                      placa: row.activo!.displayPlaca,
                                      compact: true,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.unfold_more_rounded,
                            size: 16,
                            color: subtitleColor,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppTheme.secondary.withValues(
                                alpha: 0.10,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.directions_car_outlined,
                              size: 18,
                              color: AppTheme.secondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Buscar vehículo por placa o modelo...',
                              style: TextStyle(
                                fontSize: 12,
                                color: subtitleColor,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.unfold_more_rounded,
                            size: 16,
                            color: subtitleColor,
                          ),
                        ],
                      ),
              ),
            )
          else
            SigmaTextField(
              controller: row.descripcionController,
              label: 'Descripción del ítem',
              hint: 'Ej. Maletín, radio, llaves...',
              onChanged: (_) => setState(() {}),
            ),
          const SizedBox(height: 8),
          if (row.mostrarObservacion)
            SigmaTextField(
              controller: row.observacionController,
              label: 'Observación del ítem (opcional)',
              hint: 'Estado, serie, detalle...',
            )
          else
            InkWell(
              onTap: () => setState(() => row.mostrarObservacion = true),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
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
                      'Agregar observación al ítem',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final int step;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _StepHeader({
    required this.step,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF172B4D);
    final subtitleColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? AppTheme.accentGold : AppTheme.primary,
          ),
          alignment: Alignment.center,
          child: Text(
            '$step',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFF0A1931) : Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: subtitleColor),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _ModeTabButton extends StatelessWidget {
  final bool active;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ModeTabButton({
    required this.active,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = isDark ? AppTheme.darkSurface : Colors.white;
    final activeFg = isDark ? Colors.white : AppTheme.primary;
    final inactiveFg =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        decoration: BoxDecoration(
          color: active ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13.5, color: active ? activeFg : inactiveFg),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: active ? activeFg : inactiveFg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Buscador de Funcionarios ─────────────────────────

class _FuncionarioPickerSheet extends StatefulWidget {
  final FuncionarioOption? selected;

  const _FuncionarioPickerSheet({this.selected});

  @override
  State<_FuncionarioPickerSheet> createState() =>
      _FuncionarioPickerSheetState();
}

class _FuncionarioPickerSheetState extends State<_FuncionarioPickerSheet> {
  final _service = PorteriaService.instance;
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<FuncionarioOption> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load([String? q]) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.buscarFuncionarios(query: q);
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = PorteriaService.extractErrorMessage(e);
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () {
      _load(val);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkSurface : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF172B4D);
    final subtitleColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.78,
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Seleccionar funcionario',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SigmaTextField(
              controller: _searchCtrl,
              label: 'Buscar por nombre o código',
              prefixIcon: Icons.search_rounded,
              onChanged: _onSearchChanged,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red.shade500),
                      ),
                    ),
                  )
                : _items.isEmpty
                ? const Center(
                    child: SigmaEmptyState(
                      icon: Icons.person_search_rounded,
                      title: 'Sin funcionarios coincidentes',
                      subtitle: 'Intente con otro nombre o código.',
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final isSelected = widget.selected?.id == item.id;
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.secondary.withValues(
                            alpha: 0.14,
                          ),
                          child: Text(
                            item.nombreCompleto.isNotEmpty
                                ? item.nombreCompleto[0].toUpperCase()
                                : 'F',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ),
                        title: Text(
                          item.nombreCompleto,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                        subtitle: Text(
                          [
                            if (item.codigo.isNotEmpty) item.codigo,
                            if (item.subtitle.isNotEmpty) item.subtitle,
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11.5, color: subtitleColor),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF10B981),
                              )
                            : null,
                        onTap: () => Navigator.pop(context, item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Buscador de Activos ─────────────────────────

class _ActivoPickerSheet extends StatefulWidget {
  final ActivoOption? selected;

  const _ActivoPickerSheet({this.selected});

  @override
  State<_ActivoPickerSheet> createState() => _ActivoPickerSheetState();
}

class _ActivoPickerSheetState extends State<_ActivoPickerSheet> {
  final _service = PorteriaService.instance;
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<ActivoOption> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load([String? q]) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.buscarActivos(query: q);
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = PorteriaService.extractErrorMessage(e);
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () {
      _load(val);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkSurface : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF172B4D);
    final subtitleColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.78,
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.directions_car_rounded,
                    size: 18,
                    color: AppTheme.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Seleccionar vehículo',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SigmaTextField(
              controller: _searchCtrl,
              label: 'Buscar vehículo por placa, modelo o tipo',
              prefixIcon: Icons.search_rounded,
              onChanged: _onSearchChanged,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red.shade500),
                      ),
                    ),
                  )
                : _items.isEmpty
                ? const Center(
                    child: SigmaEmptyState(
                      icon: Icons.directions_car_outlined,
                      title: 'Sin vehículos coincidentes',
                      subtitle: 'Intente con otra placa o término.',
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final isSelected = widget.selected?.id == item.id;
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        leading: VehiculoThumb(
                          urlImagen: item.urlImagen,
                          size: 40,
                          borderRadius: 8,
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.displayVehiculoNombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: titleColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            PlacaBadge(
                              placa: item.displayPlaca,
                              compact: true,
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Row(
                            children: [
                              TipoVehiculoBadge(
                                tipo: item.displayTipo,
                                compact: true,
                              ),
                              if (item.codigo.isNotEmpty &&
                                  item.codigo != item.displayPlaca) ...[
                                const SizedBox(width: 6),
                                Text(
                                  'Cód: ${item.codigo}',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: subtitleColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF10B981),
                                size: 20,
                              )
                            : null,
                        onTap: () => Navigator.pop(context, item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
