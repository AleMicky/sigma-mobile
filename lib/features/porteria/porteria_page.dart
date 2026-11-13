import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sigma_mobile/app/theme/app_theme.dart';
import 'package:sigma_mobile/core/widgets/sigma_widgets.dart';
import 'package:sigma_mobile/features/porteria/models/porteria_models.dart';
import 'package:sigma_mobile/features/porteria/services/porteria_service.dart';
import 'package:sigma_mobile/features/porteria/widgets/registrar_llegada_sheet.dart';
import 'package:sigma_mobile/features/porteria/widgets/registrar_salida_sheet.dart';
import 'package:sigma_mobile/features/porteria/widgets/vehiculo_display_widgets.dart';

const int _umbralAlertaMin = 120;
const int _umbralCriticoMin = 240;

class PorteriaPage extends StatefulWidget {
  const PorteriaPage({super.key});

  @override
  State<PorteriaPage> createState() => _PorteriaPageState();
}

class _PorteriaPageState extends State<PorteriaPage> {
  final _service = PorteriaService.instance;
  final _afueraSearchCtrl = TextEditingController();
  final _historialSearchCtrl = TextEditingController();

  Timer? _clockTimer;
  Timer? _searchDebounce;
  DateTime _now = DateTime.now();

  int _tabIndex = 0; // 0 = Afuera ahora, 1 = Historial

  // Estado Afuera
  List<RegistroPorteria> _afueraList = const [];
  bool _loadingAfuera = true;
  String? _errorAfuera;
  String _afueraQuery = '';

  // Estado Historial
  PorteriaPageResult _historialPage = const PorteriaPageResult(
    content: [],
    page: 0,
    size: 20,
    totalElements: 0,
    totalPages: 0,
  );
  bool _loadingHistorial = true;
  String? _errorHistorial;
  EstadoRegistroPorteria? _estadoFiltro; // null = TODOS
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _refreshAll();
    _clockTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _searchDebounce?.cancel();
    _afueraSearchCtrl.dispose();
    _historialSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadAfuera(), _loadHistorial()]);
  }

  Future<void> _loadAfuera() async {
    setState(() {
      _loadingAfuera = true;
      _errorAfuera = null;
    });

    try {
      final list = await _service.listarAfuera();
      // Los que llevan más tiempo afuera primero
      list.sort((a, b) => a.fechaHoraSalida.compareTo(b.fechaHoraSalida));
      if (!mounted) return;
      setState(() {
        _afueraList = list;
        _loadingAfuera = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorAfuera = PorteriaService.extractErrorMessage(e);
        _loadingAfuera = false;
      });
    }
  }

  Future<void> _loadHistorial({int? page}) async {
    final targetPage = page ?? _page;
    setState(() {
      _loadingHistorial = true;
      _errorHistorial = null;
      _page = targetPage;
    });

    try {
      final res = await _service.listar(
        page: targetPage,
        size: 20,
        search: _historialSearchCtrl.text.trim(),
        estado: _estadoFiltro,
      );
      if (!mounted) return;
      setState(() {
        _historialPage = res;
        _loadingHistorial = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorHistorial = PorteriaService.extractErrorMessage(e);
        _loadingHistorial = false;
      });
    }
  }

  void _onHistorialSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _loadHistorial(page: 0);
    });
  }

  List<RegistroPorteria> get _afueraFiltrada {
    final q = _afueraQuery.trim().toLowerCase();
    if (q.isEmpty) return _afueraList;
    return _afueraList.where((r) {
      final fields = <String?>[
        r.numero,
        r.empleadoNombre,
        r.guardiaSalidaNombre,
        r.observacionSalida,
        ...r.activos.expand((a) => [
              a.activoCodigo,
              a.activoNombre,
              a.descripcionItem,
              a.displayPlaca,
              a.displayVehiculoNombre,
            ]),
      ];
      return fields.any(
        (v) => v != null && v.toLowerCase().contains(q),
      );
    }).toList();
  }

  int get _prolongadosCount => _afueraList
      .where(
        (r) => _now.difference(r.fechaHoraSalida).inMinutes >= _umbralAlertaMin,
      )
      .length;

  int get _activosAfueraCount =>
      _afueraList.fold<int>(0, (sum, r) => sum + r.totalUnidades);

  Future<void> _openRegistrarSalida() async {
    final created = await showRegistrarSalidaPorteriaSheet(context);
    if (created != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Salida ${created.numero} registrada correctamente'),
        ),
      );
      _refreshAll();
    }
  }

  Future<void> _openRegistrarLlegada(RegistroPorteria registro) async {
    final updated = await showRegistrarLlegadaPorteriaSheet(context, registro);
    if (updated != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Llegada ${updated.numero} registrada correctamente'),
        ),
      );
      _refreshAll();
    }
  }

  Future<void> _confirmarAnular(RegistroPorteria registro) async {
    final motivoCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Anular ${registro.numero}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Desea anular la salida de ${registro.funcionarioDisplay}?',
                style: const TextStyle(fontSize: 13.5),
              ),
              const SizedBox(height: 12),
              SigmaTextField(
                controller: motivoCtrl,
                label: 'Motivo de anulación (opcional)',
                hint: 'Ej. Registro duplicado...',
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Anular registro'),
            ),
          ],
        );
      },
    );

    final motivo = motivoCtrl.text.trim();
    motivoCtrl.dispose();

    if (confirmed != true || !mounted) return;

    try {
      await _service.anular(
        registro.id,
        motivo: motivo.isEmpty ? null : motivo,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Registro ${registro.numero} anulado'),
        ),
      );
      _refreshAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
          content: Text(PorteriaService.extractErrorMessage(e)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Control de Salidas y Portería',
              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
            ),
            Text(
              'Salidas y llegadas de vehículos y personal',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFFCAD9E9),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: (_loadingAfuera || _loadingHistorial)
                ? null
                : _refreshAll,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const ThemeToggleButton(compact: true),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openRegistrarSalida,
        backgroundColor: isDark ? AppTheme.accentGold : AppTheme.primary,
        foregroundColor: isDark ? const Color(0xFF0A1931) : Colors.white,
        icon: const Icon(Icons.logout_rounded, size: 19),
        label: const Text(
          'Registrar salida',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 88),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildKpiRow(isDark),
                  const SizedBox(height: 14),
                  _buildSegmentedTabs(isDark),
                  const SizedBox(height: 14),
                  if (_tabIndex == 0)
                    _buildAfueraSection(isDark)
                  else
                    _buildHistorialSection(isDark),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiRow(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _KpiStatCard(
            label: 'Afuera ahora',
            value: '${_afueraList.length}',
            hint: '$_activosAfueraCount vehículo(s) fuera',
            icon: Icons.schedule_rounded,
            color: const Color(0xFFD97706),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _KpiStatCard(
            label: 'Prolongadas',
            value: '$_prolongadosCount',
            hint: 'Más de ${_umbralAlertaMin ~/ 60}h fuera',
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFDC2626),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _KpiStatCard(
            label: 'En historial',
            value: '${_historialPage.totalElements}',
            hint: 'Registros totales',
            icon: Icons.history_rounded,
            color: AppTheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedTabs(bool isDark) {
    final containerBg = isDark ? AppTheme.darkSurface : Colors.white;
    final activeBg = isDark ? AppTheme.accentGold : AppTheme.primary;
    final activeFg = isDark ? const Color(0xFF0A1931) : Colors.white;
    final inactiveFg =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _tabIndex == 0 ? activeBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_pin_circle_outlined,
                      size: 16,
                      color: _tabIndex == 0 ? activeFg : inactiveFg,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Afuera ahora',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: _tabIndex == 0 ? activeFg : inactiveFg,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: _tabIndex == 0
                            ? activeFg.withValues(alpha: 0.18)
                            : const Color(0xFFF59E0B).withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_afueraList.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _tabIndex == 0
                              ? activeFg
                              : const Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _tabIndex == 1 ? activeBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 16,
                      color: _tabIndex == 1 ? activeFg : inactiveFg,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Historial',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: _tabIndex == 1 ? activeFg : inactiveFg,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAfueraSection(bool isDark) {
    final list = _afueraFiltrada;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_afueraList.isNotEmpty) ...[
          SigmaTextField(
            controller: _afueraSearchCtrl,
            label: 'Filtrar por funcionario, vehículo, placa o guardia...',
            prefixIcon: Icons.search_rounded,
            suffixIcon: _afueraQuery.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _afueraSearchCtrl.clear();
                      setState(() => _afueraQuery = '');
                    },
                    icon: const Icon(Icons.close_rounded, size: 18),
                  )
                : null,
            onChanged: (val) => setState(() => _afueraQuery = val),
          ),
          const SizedBox(height: 12),
        ],
        if (_loadingAfuera)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_errorAfuera != null)
          _ErrorBanner(message: _errorAfuera!, onRetry: _loadAfuera)
        else if (_afueraList.isEmpty)
          const SigmaEmptyState(
            icon: Icons.verified_rounded,
            title: 'No hay salidas pendientes de retorno',
            subtitle:
                'Todos los vehículos y funcionarios han retornado o aún no se registraron salidas.',
          )
        else if (list.isEmpty)
          SigmaEmptyState(
            icon: Icons.search_off_rounded,
            title: 'Sin coincidencias',
            subtitle: 'Ningún registro coincide con "$_afueraQuery".',
          )
        else
          ...list.map(
            (reg) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AfueraCard(
                registro: reg,
                now: _now,
                onLlegada: () => _openRegistrarLlegada(reg),
                onAnular: () => _confirmarAnular(reg),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHistorialSection(bool isDark) {
    final titleColor = isDark ? Colors.white : const Color(0xFF172B4D);
    final subtitleColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final items = _historialPage.content;
    final groups = _groupByDay(items);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SigmaTextField(
          controller: _historialSearchCtrl,
          label: 'Buscar por número u observación...',
          prefixIcon: Icons.search_rounded,
          onChanged: _onHistorialSearchChanged,
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _EstadoFilterChip(
                label: 'Todos',
                selected: _estadoFiltro == null,
                onTap: () {
                  setState(() => _estadoFiltro = null);
                  _loadHistorial(page: 0);
                },
              ),
              const SizedBox(width: 6),
              _EstadoFilterChip(
                label: 'Afuera',
                selected: _estadoFiltro == EstadoRegistroPorteria.afuera,
                color: const Color(0xFFD97706),
                onTap: () {
                  setState(
                    () => _estadoFiltro = EstadoRegistroPorteria.afuera,
                  );
                  _loadHistorial(page: 0);
                },
              ),
              const SizedBox(width: 6),
              _EstadoFilterChip(
                label: 'Completado',
                selected: _estadoFiltro == EstadoRegistroPorteria.completado,
                color: const Color(0xFF059669),
                onTap: () {
                  setState(
                    () => _estadoFiltro = EstadoRegistroPorteria.completado,
                  );
                  _loadHistorial(page: 0);
                },
              ),
              const SizedBox(width: 6),
              _EstadoFilterChip(
                label: 'Anulado',
                selected: _estadoFiltro == EstadoRegistroPorteria.anulado,
                color: const Color(0xFFDC2626),
                onTap: () {
                  setState(
                    () => _estadoFiltro = EstadoRegistroPorteria.anulado,
                  );
                  _loadHistorial(page: 0);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (_loadingHistorial)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_errorHistorial != null)
          _ErrorBanner(message: _errorHistorial!, onRetry: _loadHistorial)
        else if (items.isEmpty)
          const SigmaEmptyState(
            icon: Icons.shield_outlined,
            title: 'Sin registros en el historial',
            subtitle: 'No se encontraron registros con los filtros actuales.',
          )
        else ...[
          ...groups.map((group) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        group.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${group.items.length} registro(s)',
                        style: TextStyle(fontSize: 11.5, color: subtitleColor),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Divider(
                          color: subtitleColor.withValues(alpha: 0.25),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SigmaCard(
                    padding: EdgeInsets.zero,
                    borderRadius: 16,
                    child: Column(
                      children: [
                        for (int i = 0; i < group.items.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          _HistorialItemTile(registro: group.items[i]),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          if (_historialPage.totalPages > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: _page > 0
                      ? () => _loadHistorial(page: _page - 1)
                      : null,
                  icon: const Icon(Icons.chevron_left_rounded, size: 18),
                  label: const Text('Anterior'),
                ),
                Text(
                  'Página ${_page + 1} de ${_historialPage.totalPages}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: subtitleColor,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _page < _historialPage.totalPages - 1
                      ? () => _loadHistorial(page: _page + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right_rounded, size: 18),
                  label: const Text('Siguiente'),
                ),
              ],
            ),
        ],
      ],
    );
  }

  List<_DayGroup> _groupByDay(List<RegistroPorteria> items) {
    final groups = <_DayGroup>[];
    for (final reg in items) {
      final dt = reg.fechaHoraSalida;
      final key = '${dt.year}-${dt.month}-${dt.day}';
      final existing = groups.where((g) => g.key == key).firstOrNull;
      if (existing != null) {
        existing.items.add(reg);
      } else {
        groups.add(
          _DayGroup(key: key, label: _dayLabel(dt), items: [reg]),
        );
      }
    }
    return groups;
  }

  String _dayLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(dt.year, dt.month, dt.day);

    if (dateOnly == today) return 'Hoy';
    if (dateOnly == yesterday) return 'Ayer';

    const meses = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${dt.day} de ${meses[dt.month - 1]} ${dt.year != now.year ? dt.year : ''}'
        .trim();
  }
}

class _DayGroup {
  final String key;
  final String label;
  final List<RegistroPorteria> items;

  _DayGroup({required this.key, required this.label, required this.items});
}

// ───────────────────────── Tarjetas y sub-widgets ─────────────────────────

class _KpiStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  final IconData icon;
  final Color color;

  const _KpiStatCard({
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF172B4D);
    final subtitleColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return SigmaCard(
      padding: const EdgeInsets.all(11),
      borderRadius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 17, color: color),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          Text(
            hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: subtitleColor),
          ),
        ],
      ),
    );
  }
}

class _AfueraCard extends StatelessWidget {
  final RegistroPorteria registro;
  final DateTime now;
  final VoidCallback onLlegada;
  final VoidCallback onAnular;

  const _AfueraCard({
    required this.registro,
    required this.now,
    required this.onLlegada,
    required this.onAnular,
  });

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

  String _formatTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.hour)}:${two(dt.minute)}';
  }

  String _formatDuration(int totalMin) {
    if (totalMin < 1) return '< 1 min';
    final d = totalMin ~/ 1440;
    final h = (totalMin % 1440) ~/ 60;
    final m = totalMin % 60;
    if (d > 0) return '${d}d ${h}h';
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '$m min';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF172B4D);
    final subtitleColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final mins = now.difference(registro.fechaHoraSalida).inMinutes;
    final Color accentColor = mins >= _umbralCriticoMin
        ? const Color(0xFFDC2626)
        : mins >= _umbralAlertaMin
        ? const Color(0xFFD97706)
        : AppTheme.secondary;

    return SigmaCard(
      padding: EdgeInsets.zero,
      borderRadius: 16,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Borde lateral de nivel
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
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
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      registro.funcionarioDisplay,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: titleColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: subtitleColor.withValues(
                                        alpha: 0.14,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      registro.numero,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: subtitleColor,
                                      ),
                                    ),
                                  ),
                                  if (registro.esExterno) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.withValues(
                                          alpha: 0.14,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'EXTERNO',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.purple,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              Wrap(
                                spacing: 10,
                                runSpacing: 3,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.logout_rounded,
                                        size: 13,
                                        color: subtitleColor,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Salió ${_formatTime(registro.fechaHoraSalida)}',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: subtitleColor,
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
                                          size: 13,
                                          color: subtitleColor,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          registro.guardiaSalidaNombre!,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: subtitleColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Badge de tiempo afuera
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                mins >= _umbralAlertaMin
                                    ? Icons.warning_amber_rounded
                                    : Icons.timer_outlined,
                                size: 13,
                                color: accentColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDuration(mins),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    _ActivosChipsWrap(activos: registro.activos),

                    if (registro.observacionSalida != null &&
                        registro.observacionSalida!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 13.5,
                            color: subtitleColor,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              registro.observacionSalida!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: subtitleColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const Divider(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: Colors.red.shade500,
                          ),
                          onPressed: onAnular,
                          icon: const Icon(Icons.cancel_outlined, size: 16),
                          label: const Text(
                            'Anular',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: onLlegada,
                          icon: const Icon(Icons.login_rounded, size: 16),
                          label: const Text(
                            'Registrar llegada',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistorialItemTile extends StatelessWidget {
  final RegistroPorteria registro;

  const _HistorialItemTile({required this.registro});

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

  String _formatTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.hour)}:${two(dt.minute)}';
  }

  String _formatDuration(int totalMin) {
    if (totalMin < 1) return '< 1m';
    final d = totalMin ~/ 1440;
    final h = (totalMin % 1440) ~/ 60;
    final m = totalMin % 60;
    if (d > 0) return '${d}d ${h}h';
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF172B4D);
    final subtitleColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final isAnulado = registro.estado == EstadoRegistroPorteria.anulado;
    final duracionMin = registro.fechaHoraLlegada
        ?.difference(registro.fechaHoraSalida)
        .inMinutes;

    final Color estadoColor = switch (registro.estado) {
      EstadoRegistroPorteria.afuera => const Color(0xFFD97706),
      EstadoRegistroPorteria.completado => const Color(0xFF059669),
      EstadoRegistroPorteria.anulado => const Color(0xFFDC2626),
    };

    return Opacity(
      opacity: isAnulado ? 0.68 : 1.0,
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: estadoColor.withValues(alpha: 0.14),
              ),
              alignment: Alignment.center,
              child: Text(
                _initials(registro.funcionarioDisplay),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: estadoColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                registro.funcionarioDisplay,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: titleColor,
                                  decoration: isAnulado
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            if (registro.esExterno) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withValues(
                                    alpha: 0.14,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'EXTERNO',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.purple,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      _EstadoBadge(estado: registro.estado),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Línea de tiempo salida -> llegada
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: subtitleColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          registro.numero,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: subtitleColor,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.logout_rounded,
                            size: 13,
                            color: Color(0xFFD97706),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _formatTime(registro.fechaHoraSalida),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: subtitleColor,
                      ),
                      if (registro.fechaHoraLlegada != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.login_rounded,
                              size: 13,
                              color: Color(0xFF059669),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _formatTime(registro.fechaHoraLlegada!),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                              ),
                            ),
                            if (duracionMin != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(${_formatDuration(duracionMin)})',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ],
                        )
                      else
                        Text(
                          isAnulado ? 'Sin llegada' : 'Pendiente de retorno',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontStyle: FontStyle.italic,
                            color: subtitleColor,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _ActivosChipsWrap(activos: registro.activos),
                  if ((registro.observacionSalida != null &&
                          registro.observacionSalida!.isNotEmpty) ||
                      (registro.observacionLlegada != null &&
                          registro.observacionLlegada!.isNotEmpty)) ...[
                    const SizedBox(height: 6),
                    if (registro.observacionSalida != null &&
                        registro.observacionSalida!.isNotEmpty)
                      Text(
                        'Salida: ${registro.observacionSalida}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: subtitleColor),
                      ),
                    if (registro.observacionLlegada != null &&
                        registro.observacionLlegada!.isNotEmpty)
                      Text(
                        'Llegada: ${registro.observacionLlegada}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: subtitleColor),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivosChipsWrap extends StatefulWidget {
  final List<RegistroPorteriaActivo> activos;

  const _ActivosChipsWrap({required this.activos});

  @override
  State<_ActivosChipsWrap> createState() => _ActivosChipsWrapState();
}

class _ActivosChipsWrapState extends State<_ActivosChipsWrap> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    if (widget.activos.isEmpty) {
      return Text(
        'Sin vehículos registrados',
        style: TextStyle(
          fontSize: 11.5,
          fontStyle: FontStyle.italic,
          color: subtitleColor,
        ),
      );
    }

    // Por defecto se muestra ÚNICAMENTE 1 ítem (el vehículo principal)
    final itemsToShow = _expanded ? widget.activos : [widget.activos.first];
    final remainingCount = widget.activos.length - 1;

    return Wrap(
      spacing: 5,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...itemsToShow.map((item) => _buildItemChip(item, isDark, subtitleColor)),
        if (remainingCount > 0)
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _expanded ? 'Ver menos' : '+$remainingCount más',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildItemChip(
    RegistroPorteriaActivo item,
    bool isDark,
    Color subtitleColor,
  ) {
    final noRetorno = item.retornado == false;
    final chipColor = noRetorno
        ? const Color(0xFFDC2626)
        : (isDark ? Colors.white : const Color(0xFF1E293B));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: noRetorno
            ? const Color(0xFFDC2626).withValues(alpha: 0.12)
            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: noRetorno
              ? const Color(0xFFDC2626).withValues(alpha: 0.4)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.directions_car_rounded,
            size: 13,
            color: noRetorno
                ? const Color(0xFFDC2626)
                : const Color(0xFF0284C7),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              item.displayVehiculoNombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: chipColor,
              ),
            ),
          ),
          if (item.displayPlaca.isNotEmpty) ...[
            const SizedBox(width: 4),
            PlacaBadge(placa: item.displayPlaca, compact: true),
          ],
          if (item.cantidad > 1) ...[
            const SizedBox(width: 3),
            Text(
              '×${item.cantidad}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: subtitleColor,
              ),
            ),
          ],
          if (noRetorno) ...[
            const SizedBox(width: 3),
            const Text(
              '· No retornó',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFFDC2626),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final EstadoRegistroPorteria estado;

  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon) = switch (estado) {
      EstadoRegistroPorteria.afuera => (
        const Color(0xFFD97706),
        Icons.schedule_rounded,
      ),
      EstadoRegistroPorteria.completado => (
        const Color(0xFF059669),
        Icons.check_circle_outline_rounded,
      ),
      EstadoRegistroPorteria.anulado => (
        const Color(0xFFDC2626),
        Icons.cancel_outlined,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3.5),
          Text(
            estado.label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _EstadoFilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppTheme.primary;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: selected ? activeColor : null,
        ),
      ),
      selected: selected,
      selectedColor: activeColor.withValues(alpha: 0.16),
      onSelected: (_) => onTap(),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SigmaCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 14,
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 28,
            color: Colors.red.shade500,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

