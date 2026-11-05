import 'package:flutter/material.dart';
import 'package:sigma_mobile/app/theme/app_theme.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedIndex = 0;

  final modules = const [
    _Module(
      title: 'Control de salidas',
      icon: Icons.route_outlined,
      color: Color(0xFF2563EB),
    ),
    _Module(
      title: 'Gestión vehicular',
      icon: Icons.directions_car_outlined,
      color: Color(0xFF0F766E),
    ),
    _Module(
      title: 'Mantenimiento',
      icon: Icons.build_outlined,
      color: Color(0xFFA16207),
    ),
    _Module(
      title: 'Incidentes',
      icon: Icons.warning_amber_rounded,
      color: Color(0xFFDC2626),
    ),
  ];

  void showPending(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature estará disponible próximamente'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: selectedIndex,
          children: [
            _buildHome(),
            _buildModulesPage(),
            _buildPlaceholder(Icons.notifications_none, 'Notificaciones'),
            _buildPlaceholder(Icons.person_outline, 'Mi perfil'),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            label: 'Módulos',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            label: 'Avisos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildHome() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildSummary(),
              const SizedBox(height: 24),
              _buildSectionTitle(
                'Módulos principales',
                action: 'Ver todos',
                onAction: () {
                  setState(() => selectedIndex = 1);
                },
              ),
              const SizedBox(height: 12),
              _buildModuleGrid(),
              const SizedBox(height: 24),
              _buildSectionTitle('Actividad reciente'),
              const SizedBox(height: 12),
              _buildEmptyActivity(),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.business, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SIGMA',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'ENDE CORANI',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFCAD9E9),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Notificaciones',
                onPressed: () {
                  setState(() => selectedIndex = 2);
                },
                icon: const Icon(Icons.notifications_none, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Bienvenido a',
            style: TextStyle(color: Color(0xFFCAD9E9), fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'SIGMA Mobile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gestión de activos, mantenimiento y vehículos',
            style: TextStyle(color: Color(0xFFDFE8F2), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: AppTheme.secondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Actividades y solicitudes',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Los datos estarán disponibles al '
                    'conectar tu cuenta institucional.',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    String title, {
    String? action,
    VoidCallback? onAction,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF172B4D),
            ),
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action)),
      ],
    );
  }

  Widget _buildModuleGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 132,
          ),
          itemCount: modules.length,
          itemBuilder: (context, index) {
            return _buildModuleCard(modules[index]);
          },
        );
      },
    );
  }

  Widget _buildModuleCard(_Module module) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showPending(module.title),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: module.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(module.icon, color: module.color, size: 26),
              ),
              const Spacer(),
              Text(
                module.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF172B4D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.assignment_outlined,
                size: 44,
                color: Colors.blueGrey,
              ),
              const SizedBox(height: 12),
              const Text(
                'Sin actividades para mostrar',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                'Se mostrarán al integrar el backend',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModulesPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Módulos de SIGMA'),
        const SizedBox(height: 16),
        _buildModuleGrid(),
      ],
    );
  }

  Widget _buildPlaceholder(IconData icon, String title) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppTheme.primary),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'Disponible en una próxima etapa',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _Module {
  final String title;
  final IconData icon;
  final Color color;

  const _Module({required this.title, required this.icon, required this.color});
}
