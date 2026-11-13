import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sigma_mobile/app/theme/app_theme.dart';
import 'package:sigma_mobile/core/widgets/sigma_widgets.dart';
import 'package:sigma_mobile/features/solicitud_vehicular/models/solicitud_vehicular_models.dart';
import 'package:sigma_mobile/features/solicitud_vehicular/services/solicitud_vehicular_service.dart';
import 'package:sigma_mobile/features/solicitud_vehicular/widgets/nueva_solicitud_sheet.dart';
import 'package:sigma_mobile/features/solicitud_vehicular/widgets/solicitud_detalle_sheet.dart';

class SolicitudVehicularPage extends StatefulWidget {
  const SolicitudVehicularPage({super.key});

  @override
  State<SolicitudVehicularPage> createState() => _SolicitudVehicularPageState();
}

class _SolicitudVehicularPageState extends State<SolicitudVehicularPage> {
  final _service = SolicitudVehicularService.instance;
  final _searchCtrl = TextEditingController();

  Timer? _searchDebounce;

  // Filtro de Estado: null = Todas, 'PENDIENTE', 'APROBADA', 'EN_CURSO', 'FINALIZADA'
  String? _filtroEstado;

  // Estado de lista
  SolicitudVehicularPageResult _pageResult = const SolicitudVehicularPageResult(
    content: [],
    page: 0,
    size: 20,
    totalElements: 0,
    totalPages: 0,
  );
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 0;

  // Tipos disponibles para el selector
  List<TipoSolicitudVehicular> _tipos = const [];

  @override
  void initState() {
    super.initState();
    _loadTipos();
    _loadSolicitudes();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTipos() async {
    final list = await _service.listarTipos();
    if (mounted) setState(() => _tipos = list);
  }

  Future<void> _loadSolicitudes({int? page}) async {
    final targetPage = page ?? _currentPage;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = targetPage;
    });

    try {
      final res = await _service.listar(
        page: targetPage,
        size: 20,
        search: _searchCtrl.text.trim(),
        estado: _filtroEstado,
      );
      if (!mounted) return;
      setState(() {
        _pageResult = res;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = SolicitudVehicularService.extractErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String text) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _loadSolicitudes(page: 0);
    });
  }

  void _openNuevaSolicitud() {
    NuevaSolicitudSheet.show(
      context,
      tipos: _tipos,
      onCreated: () => _loadSolicitudes(page: 0),
    );
  }

  void _openDetalle(SolicitudVehicular sol) {
    SolicitudDetalleSheet.show(
      context,
      solicitud: sol,
      onUpdated: () => _loadSolicitudes(),
    );
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y  $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNuevaSolicitud,
        backgroundColor: isDark ? AppTheme.accentGold : AppTheme.primary,
        foregroundColor: isDark ? Colors.black : Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Nueva Solicitud',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilterChips(),
            const Divider(height: 1),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadSolicitudes(page: 0),
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF13223E), const Color(0xFF0A1428)]
              : [AppTheme.primary, const Color(0xFF15397F)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => context.pop(),
            tooltip: 'Volver',
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.accentGold.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Text(
                        'GESTIÓN VEHICULAR',
                        style: TextStyle(
                          color: AppTheme.accentGold,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${_pageResult.totalElements} registros',
                      style: const TextStyle(color: Color(0xFFCAD9E9), fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Solicitudes Vehiculares',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Recargar',
            onPressed: () => _loadSolicitudes(),
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Buscar por destino, número o motivo...',
            hintStyle: const TextStyle(fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      _loadSolicitudes(page: 0);
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filtros = <Map<String, String?>>[
      {'label': 'Todas', 'value': null},
      {'label': 'Pendientes', 'value': 'PENDIENTE'},
      {'label': 'Aprobadas', 'value': 'APROBADA'},
      {'label': 'En curso', 'value': 'EN_CURSO'},
      {'label': 'Finalizadas', 'value': 'FINALIZADA'},
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: filtros.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = filtros[index];
          final isSelected = _filtroEstado == item['value'];

          return FilterChip(
            selected: isSelected,
            label: Text(
              item['label']!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            onSelected: (selected) {
              setState(() => _filtroEstado = item['value']);
              _loadSolicitudes(page: 0);
            },
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13.5),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _loadSolicitudes(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_pageResult.content.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 60),
          SigmaEmptyState(
            icon: Icons.directions_car_outlined,
            title: 'No hay solicitudes vehiculares',
            subtitle: _searchCtrl.text.isNotEmpty || _filtroEstado != null
                ? 'Prueba cambiando los términos de búsqueda o filtros.'
                : 'Crea tu primera solicitud vehicular usando el botón "+ Nueva Solicitud".',
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 80),
      itemCount: _pageResult.content.length,
      itemBuilder: (context, index) {
        final sol = _pageResult.content[index];
        return _buildSolicitudCard(sol);
      },
    );
  }

  Widget _buildSolicitudCard(SolicitudVehicular sol) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final estado = sol.estado;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SigmaCard(
        padding: const EdgeInsets.all(13),
        borderRadius: 16,
        onTap: () => _openDetalle(sol),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila 1: Número, Tipo y Estado Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    sol.numero,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                if (sol.tipoSolicitud != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: sol.tipoSolicitud!.esEmergencia
                          ? Colors.red.shade100.withValues(alpha: isDark ? 0.2 : 0.8)
                          : const Color(0xFF0284C7).withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      sol.tipoSolicitud!.nombre.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: sol.tipoSolicitud!.esEmergencia
                            ? (isDark ? Colors.red.shade300 : Colors.red.shade900)
                            : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1)),
                      ),
                    ),
                  ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: estado.color.withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: estado.color.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(estado.icon, size: 12, color: estado.color),
                      const SizedBox(width: 4),
                      Text(
                        estado.label,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: estado.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Fila 2: Destino (Destacado)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF0284C7)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    sol.destino,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: Colors.grey.withValues(alpha: 0.6),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Fila 3: Motivo
            Text(
              sol.motivo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Fila 4: Fechas y Pasajeros
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Salida: ${_formatDateTime(sol.fechaSalida)}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people_alt_outlined, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        '${sol.cantidadPasajeros}',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Fila 5: Asignación (si existe)
            if (sol.activoPlaca != null || sol.conductorAsignado != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50.withValues(alpha: isDark ? 0.15 : 0.8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.directions_car_rounded, size: 13, color: Colors.green.shade700),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        [
                          if (sol.activoPlaca != null) 'Placa: ${sol.activoPlaca}',
                          if (sol.conductorAsignado?.nombreCompleto != null)
                            'Conductor: ${sol.conductorAsignado!.nombreCompleto}',
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.green.shade300 : Colors.green.shade900,
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
    );
  }
}

