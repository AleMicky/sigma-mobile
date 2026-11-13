import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sigma_mobile/app/theme/app_theme.dart';
import 'package:sigma_mobile/core/widgets/sigma_card.dart';
import 'package:sigma_mobile/core/widgets/theme_toggle_button.dart';
import 'package:sigma_mobile/features/porteria/widgets/vehiculo_display_widgets.dart';
import 'package:sigma_mobile/features/salida_vehicular/models/salida_vehicular_models.dart';
import 'package:sigma_mobile/features/salida_vehicular/services/salida_vehicular_service.dart';
import 'package:sigma_mobile/features/salida_vehicular/widgets/detalle_salida_sheet.dart';
import 'package:sigma_mobile/features/salida_vehicular/widgets/nueva_salida_sheet.dart';
import 'package:sigma_mobile/features/salida_vehicular/widgets/registrar_retorno_sheet.dart';

class SalidaVehicularPage extends StatefulWidget {
  const SalidaVehicularPage({super.key});

  @override
  State<SalidaVehicularPage> createState() => _SalidaVehicularPageState();
}

class _SalidaVehicularPageState extends State<SalidaVehicularPage> {
  final _service = SalidaVehicularService.instance;
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  List<SalidaVehicular> _salidas = [];
  bool _isLoading = true;
  String? _error;

  String _estadoFiltro = ''; // '' = Todas, 'SALIDA', 'LLEGADA', 'CANCELADA'
  String _searchQuery = '';
  int _page = 0;
  int _totalElements = 0;

  @override
  void initState() {
    super.initState();
    _cargarSalidas();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarSalidas({bool refresh = false}) async {
    if (refresh) {
      _page = 0;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _service.listar(
        page: _page,
        size: 30,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        estado: _estadoFiltro.isEmpty ? null : _estadoFiltro,
      );

      if (!mounted) return;
      setState(() {
        _salidas = result.content;
        _totalElements = result.totalElements;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'No se pudieron cargar las salidas vehiculares: ${e.toString().replaceAll('Exception:', '')}';
      });
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (_searchQuery != query.trim()) {
        setState(() {
          _searchQuery = query.trim();
        });
        _cargarSalidas(refresh: true);
      }
    });
  }

  int get _countEnRuta => _salidas.where((s) => s.isEnRuta).length;
  int get _countFinalizadas => _salidas.where((s) => s.isFinalizada).length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _cargarSalidas(refresh: true),
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(child: _buildHeader(isDark)),

              // Filtros y Buscador
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // KPI Resumen
                      _buildSummaryRow(isDark),
                      const SizedBox(height: 12),

                      // Buscador
                      TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Buscar por placa, destino, conductor o N°...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark ? Colors.white24 : Colors.black12,
                            ),
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('', 'Todas', null),
                            const SizedBox(width: 8),
                            _buildFilterChip('SALIDA', 'En ruta', const Color(0xFF0284C7)),
                            const SizedBox(width: 8),
                            _buildFilterChip('LLEGADA', 'Finalizadas', const Color(0xFF0F766E)),
                            const SizedBox(width: 8),
                            _buildFilterChip('CANCELADA', 'Canceladas', Colors.red.shade700),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Lista o Estados Vacíos
              if (_isLoading && _salidas.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null && _salidas.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 40),
                          const SizedBox(height: 12),
                          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            onPressed: () => _cargarSalidas(refresh: true),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_salidas.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_car_filled_outlined, size: 44, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          const Text(
                            'No se encontraron salidas vehiculares',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Registra una nueva salida o modifica los filtros.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final salida = _salidas[index];
                        return _buildSalidaCard(salida, isDark);
                      },
                      childCount: _salidas.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Nueva Salida',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: () async {
          final creada = await NuevaSalidaSheet.show(context);
          if (creada == true) {
            _cargarSalidas(refresh: true);
          }
        },
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF13223E), const Color(0xFF0A1428)]
              : [const Color(0xFF0284C7), const Color(0xFF0369A1)],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF0284C7)).withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Control de Salidas',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Gestión de viajes y comisiones vehiculares',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFFDFE8F2),
                      ),
                    ),
                  ],
                ),
              ),
              const ThemeToggleButton(compact: true),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 21),
                onPressed: () => _cargarSalidas(refresh: true),
                tooltip: 'Refrescar',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(bool isDark) {
    return Row(
      children: [
        _buildMetricBox(
          'Total Salidas',
          '$_totalElements',
          Icons.route_rounded,
          const Color(0xFF0284C7),
          isDark,
        ),
        const SizedBox(width: 8),
        _buildMetricBox(
          'En Ruta',
          '$_countEnRuta',
          Icons.directions_car_rounded,
          const Color(0xFFD97706),
          isDark,
        ),
        const SizedBox(width: 8),
        _buildMetricBox(
          'Finalizadas',
          '$_countFinalizadas',
          Icons.check_circle_rounded,
          const Color(0xFF0F766E),
          isDark,
        ),
      ],
    );
  }

  Widget _buildMetricBox(String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF172B4D),
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white60 : Colors.black54,
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

  Widget _buildFilterChip(String valor, String label, Color? color) {
    final isSelected = _estadoFiltro == valor;
    final activeColor = color ?? const Color(0xFF0284C7);

    return InkWell(
      onTap: () {
        setState(() => _estadoFiltro = valor);
        _cargarSalidas(refresh: true);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.18) : Colors.transparent,
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? activeColor : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildSalidaCard(SalidaVehicular salida, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: SigmaCard(
        padding: const EdgeInsets.all(12),
        borderRadius: 14,
        onTap: () => DetalleSalidaSheet.show(
          context,
          salida,
          onActualizado: () => _cargarSalidas(refresh: true),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: Número y Estado Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        salida.numero.isNotEmpty ? salida.numero : 'SALIDA',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${salida.fecha.day.toString().padLeft(2, '0')}/${salida.fecha.month.toString().padLeft(2, '0')} ${salida.fecha.hour.toString().padLeft(2, '0')}:${salida.fecha.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: salida.estadoColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: salida.estadoColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    salida.estadoLabel,
                    style: TextStyle(
                      color: salida.estadoColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Vehículo Info
            Row(
              children: [
                const VehiculoThumb(size: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        salida.displayVehiculo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          PlacaBadge(placa: salida.displayPlaca),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Chofer: ${salida.displayConductor}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
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

            // Actividad / Destino
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                salida.descripcionActividad,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5, height: 1.25),
              ),
            ),

            // Kilometraje / Acciones Rápidas
            if (salida.isEnRuta) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.speed_rounded, size: 14, color: Color(0xFF0284C7)),
                      const SizedBox(width: 4),
                      Text(
                        salida.kilometrajeInicial != null
                            ? '${salida.kilometrajeInicial!.toStringAsFixed(0)} km inicio'
                            : 'Km no registrado',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () async {
                      final ok = await RegistrarRetornoSheet.show(context, salida);
                      if (ok == true) {
                        _cargarSalidas(refresh: true);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF0F766E)),
                          SizedBox(width: 4),
                          Text(
                            'Registrar Llegada',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (salida.recorridoKm != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.done_all_rounded, size: 14, color: Color(0xFF0F766E)),
                  const SizedBox(width: 4),
                  Text(
                    'Trayecto finalizado · Recorrió ${salida.recorridoKm!.toStringAsFixed(0)} km',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF0F766E), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

