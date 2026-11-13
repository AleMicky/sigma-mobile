import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sigma_mobile/app/theme/app_theme.dart';
import 'package:sigma_mobile/core/config/app_config.dart';
import 'package:sigma_mobile/core/widgets/sigma_widgets.dart';
import 'package:sigma_mobile/features/auth/auth_service.dart';
import 'package:sigma_mobile/features/settings/api_config_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedIndex = 0;
  bool isLoggingOut = false;

  final authService = AuthService.instance;

  final modules = const [
    _Module(
      title: 'Control de salidas',
      subtitle: 'Viajes y comisiones vehiculares',
      icon: Icons.route_rounded,
      color: Color(0xFF0284C7),
      route: '/salidas-vehiculares',
    ),
    _Module(
      title: 'Solicitud vehicular',
      subtitle: 'Solicitudes y seguimiento',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF0F766E),
      route: '/solicitudes-vehiculares',
    ),
    _Module(
      title: 'Control de portería',
      subtitle: 'Registro vehicular y garita',
      icon: Icons.verified_user_rounded,
      color: Color(0xFF2563EB),
      route: '/porteria',
    ),
    _Module(
      title: 'Mantenimiento',
      subtitle: 'Preventivo y correctivo',
      icon: Icons.build_circle_outlined,
      color: Color(0xFFD97706),
    ),
    _Module(
      title: 'Incidentes',
      subtitle: 'Reportes y novedades',
      icon: Icons.warning_amber_rounded,
      color: Color(0xFFDC2626),
    ),
  ];

  String get userName =>
      authService.user?['name']?.toString() ?? 'Usuario SIGMA';

  String get username => authService.user?['username']?.toString() ?? '';

  String get email => authService.user?['email']?.toString() ?? '';

  List<String> get roles {
    final value = authService.user?['roles'];

    if (value is List) {
      return value.map((role) => role.toString()).toList();
    }

    return [];
  }

  void showPending(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature estará disponible próximamente'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Cerrar sesión'),
          content: const Text('¿Estás seguro de que deseas cerrar tu sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => isLoggingOut = true);

    try {
      await authService.logout();
      // GoRouter redirige automáticamente a /login.
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sesión cerrada localmente. '
            'No se pudo confirmar el cierre en el servidor.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoggingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: authService,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: IndexedStack(
              index: selectedIndex,
              children: [
                _buildHome(),
                _buildModulesPage(),
                _buildNotificationsPage(),
                _buildProfilePage(),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                setState(() => selectedIndex = index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Inicio',
                ),
                NavigationDestination(
                  icon: Icon(Icons.grid_view_outlined),
                  selectedIcon: Icon(Icons.grid_view_rounded),
                  label: 'Módulos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.notifications_outlined),
                  selectedIcon: Icon(Icons.notifications_rounded),
                  label: 'Avisos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Perfil',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHome() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildSummary(),
              const SizedBox(height: 16),
              SigmaSectionHeader(
                title: 'Módulos principales',
                actionLabel: 'Ver todos',
                onAction: () {
                  setState(() => selectedIndex = 1);
                },
              ),
              const SizedBox(height: 8),
              _buildModuleGrid(),
              const SizedBox(height: 18),
              const SigmaSectionHeader(title: 'Actividad reciente'),
              const SizedBox(height: 8),
              const SigmaEmptyState(
                icon: Icons.assignment_outlined,
                title: 'Sin actividades para mostrar',
                subtitle: 'Las actividades aparecerán al integrar los módulos',
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return Container(
      padding: EdgeInsets.fromLTRB(
        isCompact ? 14 : 16,
        10,
        isCompact ? 14 : 16,
        16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF13223E), const Color(0xFF0A1428)]
              : [AppTheme.primary, const Color(0xFF15397F)],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppTheme.primary).withValues(
              alpha: 0.18,
            ),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset(
                  'assets/logo-ende-corani.png',
                  height: isCompact ? 20 : 24,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SIGMA',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isCompact ? 14.5 : 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Text(
                      'ENDE CORANI',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFFCAD9E9),
                        letterSpacing: 0.9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const ThemeToggleButton(compact: true),
              IconButton(
                tooltip: 'Notificaciones',
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  setState(() => selectedIndex = 2);
                },
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.accentGold.withValues(alpha: 0.45),
                  ),
                ),
                child: const Text(
                  'PANEL OPERATIVO',
                  style: TextStyle(
                    color: AppTheme.accentGold,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '•  Bienvenido,',
                style: TextStyle(color: Color(0xFFCAD9E9), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            userName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: isCompact ? 17.5 : 19.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Gestión institucional de activos, mantenimiento y vehículos',
            style: TextStyle(color: Color(0xFFDFE8F2), fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF172B4D);
    final subtitleColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return SigmaCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 14,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.accentGold.withValues(alpha: 0.14)
                  : AppTheme.secondary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: isDark ? AppTheme.accentGold : AppTheme.secondary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Actividades y solicitudes',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Consulta los módulos disponibles. Las actividades operativas se mostrarán al conectar sus servicios.',
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 600
            ? 3
            : width < 290
            ? 1
            : 2;
        final isCompactCard = width < 350 && columns == 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: isCompactCard ? 104 : 112,
          ),
          itemCount: modules.length,
          itemBuilder: (context, index) {
            return _buildModuleCard(modules[index], compact: isCompactCard);
          },
        );
      },
    );
  }

  Widget _buildModuleCard(_Module module, {bool compact = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF172B4D);
    final subtitleColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return SigmaCard(
      padding: EdgeInsets.all(compact ? 10 : 12),
      borderRadius: 14,
      onTap: () {
        if (module.route != null) {
          context.push(module.route!);
        } else {
          showPending(module.title);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: compact ? 32 : 36,
                height: compact ? 32 : 36,
                decoration: BoxDecoration(
                  color: module.color.withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  module.icon,
                  color: module.color,
                  size: compact ? 18 : 20,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 11,
                color: subtitleColor.withValues(alpha: 0.6),
              ),
            ],
          ),
          const Spacer(),
          Text(
            module.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: compact ? 12.5 : 13,
              height: 1.15,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            module.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 10.5 : 11,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModulesPage() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const SigmaSectionHeader(title: 'Módulos de SIGMA'),
        const SizedBox(height: 10),
        _buildModuleGrid(),
      ],
    );
  }

  Widget _buildNotificationsPage() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: const [
        SigmaSectionHeader(title: 'Centro de avisos'),
        SizedBox(height: 10),
        SigmaEmptyState(
          icon: Icons.notifications_none_rounded,
          title: 'No tienes notificaciones pendientes',
          subtitle: 'Aquí recibirás alertas de salidas, mantenimiento y flota.',
        ),
      ],
    );
  }

  Widget _buildProfilePage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF172B4D);
    final subtitleColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final iconColor = isDark ? AppTheme.accentGold : AppTheme.primary;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Expanded(child: SigmaSectionHeader(title: 'Mi perfil')),
            ThemeToggleButton(),
          ],
        ),
        const SizedBox(height: 12),
        SigmaCard(
          padding: const EdgeInsets.all(14),
          borderRadius: 16,
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? AppTheme.accentGold.withValues(alpha: 0.15)
                      : AppTheme.primary.withValues(alpha: 0.08),
                  border: Border.all(
                    color: isDark
                        ? AppTheme.accentGold.withValues(alpha: 0.4)
                        : AppTheme.primary.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Icon(Icons.person_rounded, size: 28, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    if (username.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '@$username',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: subtitleColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SigmaCard(
          padding: EdgeInsets.zero,
          borderRadius: 16,
          child: Column(
            children: [
              ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                leading: Icon(Icons.badge_outlined, size: 20, color: iconColor),
                title: Text(
                  'Usuario',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                subtitle: Text(
                  username.isEmpty ? 'No especificado' : username,
                  style: TextStyle(fontSize: 11.5, color: subtitleColor),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                leading: Icon(Icons.email_outlined, size: 20, color: iconColor),
                title: Text(
                  'Correo electrónico',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                subtitle: Text(
                  email.isEmpty ? 'No especificado' : email,
                  style: TextStyle(fontSize: 11.5, color: subtitleColor),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                leading: Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 20,
                  color: iconColor,
                ),
                title: Text(
                  'Roles asignados',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                subtitle: Text(
                  roles.isEmpty ? 'Sin roles disponibles' : roles.join(', '),
                  style: TextStyle(fontSize: 11.5, color: subtitleColor),
                ),
              ),
              const Divider(height: 1),
              ValueListenableBuilder<String>(
                valueListenable: AppConfig.apiBaseUrlNotifier,
                builder: (context, currentUrl, _) {
                  final isCustom = AppConfig.isCustomUrl;
                  return ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    leading: Icon(
                      Icons.settings_ethernet_rounded,
                      size: 20,
                      color: iconColor,
                    ),
                    title: Text(
                      'Servidor SIGMA API',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    subtitle: Text(
                      isCustom
                          ? 'Configuración personalizada'
                          : 'Configuración institucional por defecto',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: subtitleColor),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: subtitleColor,
                    ),
                    onTap: () => showApiConfigSheet(context),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                leading: Icon(
                  Icons.my_location_rounded,
                  size: 20,
                  color: iconColor,
                ),
                title: Text(
                  'Geolocalización y bienvenida',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                subtitle: Text(
                  'Verificar permisos GPS y pantalla de bienvenida',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: subtitleColor),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: subtitleColor,
                ),
                onTap: () => authService.resetOnboarding(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 44,
          child: OutlinedButton.icon(
            onPressed: isLoggingOut ? null : logout,
            icon: isLoggingOut
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_rounded, size: 18),
            label: Text(
              isLoggingOut ? 'Cerrando sesión...' : 'Cerrar sesión',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark
                  ? Colors.red.shade300
                  : Colors.red.shade700,
              side: BorderSide(
                color: isDark ? Colors.red.shade400 : Colors.red.shade300,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Module {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? route;

  const _Module({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.route,
  });
}
