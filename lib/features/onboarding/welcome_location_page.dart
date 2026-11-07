import 'package:flutter/material.dart';
import 'package:sigma_mobile/app/theme/app_theme.dart';
import 'package:sigma_mobile/core/services/location_service.dart';
import 'package:sigma_mobile/core/widgets/sigma_widgets.dart';
import 'package:sigma_mobile/features/auth/auth_service.dart';

class WelcomeLocationPage extends StatefulWidget {
  const WelcomeLocationPage({super.key});

  @override
  State<WelcomeLocationPage> createState() => _WelcomeLocationPageState();
}

class _WelcomeLocationPageState extends State<WelcomeLocationPage>
    with WidgetsBindingObserver {
  final _authService = AuthService.instance;
  final _locationService = LocationService.instance;

  SigmaLocationState? _locationState;
  bool _isChecking = true;
  bool _isRequesting = false;
  bool _isCompleting = false;
  String? _feedbackMessage;
  bool _isFeedbackError = false;

  String get _userName =>
      _authService.user?['name']?.toString() ?? 'Usuario SIGMA';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshLocationStatus();
    }
  }

  Future<void> _checkInitialStatus() async {
    setState(() => _isChecking = true);
    final status = await _locationService.checkStatus(fetchPosition: true);
    if (!mounted) return;
    setState(() {
      _locationState = status;
      _isChecking = false;
      if (status.isReady) {
        _feedbackMessage = 'Geolocalización activa y verificada. Ya puedes ingresar al sistema.';
        _isFeedbackError = false;
      }
    });
  }

  Future<void> _refreshLocationStatus() async {
    final status = await _locationService.checkStatus(fetchPosition: true);
    if (!mounted) return;
    setState(() {
      _locationState = status;
      if (status.isReady) {
        _feedbackMessage = 'Geolocalización activa y verificada. Ya puedes ingresar al sistema.';
        _isFeedbackError = false;
      }
    });
  }

  Future<void> _handleActivateLocation() async {
    setState(() {
      _isRequesting = true;
      _feedbackMessage = null;
    });

    try {
      final (result, state) = await _locationService
          .requestLocationActivation();
      if (!mounted) return;

      setState(() {
        _locationState = state;
      });

      switch (result) {
        case SigmaLocationResult.granted:
          setState(() {
            _feedbackMessage = '¡Excelente! La geolocalización ha sido activada correctamente.';
            _isFeedbackError = false;
          });
        case SigmaLocationResult.serviceDisabled:
          setState(() {
            _feedbackMessage = 'El GPS de tu dispositivo está desactivado. Actívalo para continuar.';
            _isFeedbackError = true;
          });
          await _showSettingsDialog(
            title: 'Activar GPS del dispositivo',
            message: 'Para utilizar SIGMA es necesario encender los servicios de ubicación (GPS) de tu dispositivo.',
            actionLabel: 'Abrir ajustes de ubicación',
            onConfirm: _locationService.openLocationSettings,
          );
        case SigmaLocationResult.permissionDenied:
          setState(() {
            _feedbackMessage =
                'Debes conceder el permiso de ubicación para poder continuar.';
            _isFeedbackError = true;
          });
        case SigmaLocationResult.permissionDeniedForever:
          setState(() {
            _feedbackMessage = 'El permiso de ubicación fue bloqueado permanentemente. Habilítalo desde los ajustes de la aplicación.';
            _isFeedbackError = true;
          });
          await _showSettingsDialog(
            title: 'Permiso de ubicación requerido',
            message: 'Has bloqueado el acceso a la ubicación. Abre la configuración de la aplicación y selecciona "Permitir mientras se usa la app".',
            actionLabel: 'Abrir ajustes de la app',
            onConfirm: _locationService.openAppSettings,
          );
        case SigmaLocationResult.error:
          setState(() {
            _feedbackMessage = 'Ocurrió un inconveniente al verificar el GPS. Intenta nuevamente.';
            _isFeedbackError = true;
          });
      }
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  Future<void> _showSettingsDialog({
    required String title,
    required String message,
    required String actionLabel,
    required Future<bool> Function() onConfirm,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await onConfirm();
              },
              child: Text(actionLabel),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleContinueToDashboard() async {
    if (_locationState?.isReady != true) {
      await _handleActivateLocation();
      return;
    }

    setState(() => _isCompleting = true);
    try {
      await _authService.completeOnboarding();
      // GoRouter redirige automáticamente a '/' al completarse el onboarding.
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 360 || size.height < 700;
    final isReady = _locationState?.isReady ?? false;

    final titleColor = isDark ? Colors.white : const Color(0xFF0A2458);
    final subtitleColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF475569);

    return Scaffold(
      body: Stack(
        children: [
          // Decoración ambiental institucional
          Positioned(
            top: -100,
            right: -70,
            child: IgnorePointer(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.accentGold.withValues(
                        alpha: isDark ? 0.14 : 0.16,
                      ),
                      AppTheme.accentGold.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -110,
            left: -80,
            child: IgnorePointer(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (isDark ? const Color(0xFF1E40AF) : AppTheme.primary)
                          .withValues(alpha: isDark ? 0.22 : 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Barra superior
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isCompact ? 12 : 16,
                    4,
                    isCompact ? 12 : 16,
                    0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () => _authService.logout(),
                        icon: const Icon(Icons.logout_rounded, size: 16),
                        label: const Text(
                          'Cambiar cuenta',
                          style: TextStyle(fontSize: 12.5),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: subtitleColor,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const ThemeToggleButton(),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 14 : 18,
                        vertical: 8,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Encabezado de bienvenida compacto
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SigmaBrandLogo(height: isCompact ? 42 : 48),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 3.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentGold.withValues(
                                      alpha: isDark ? 0.16 : 0.18,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppTheme.accentGold.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'PRIMER INICIO',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.9,
                                      color: isDark
                                          ? AppTheme.accentGold
                                          : const Color(0xFF856404),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '¡Bienvenido a SIGMA, $_userName!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isCompact ? 18 : 20,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Configura el acceso a tu ubicación para habilitar los módulos operativos de ENDE CORANI.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.3,
                                color: subtitleColor,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Tarjeta principal de Geolocalización Requerida
                            _buildLocationRequirementCard(
                              isDark: isDark,
                              isCompact: isCompact,
                              isReady: isReady,
                              titleColor: titleColor,
                              subtitleColor: subtitleColor,
                            ),
                            const SizedBox(height: 10),

                            // Resumen de beneficios operativos
                            _buildFeaturesCard(
                              isDark: isDark,
                              titleColor: titleColor,
                              subtitleColor: subtitleColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRequirementCard({
    required bool isDark,
    required bool isCompact,
    required bool isReady,
    required Color titleColor,
    required Color subtitleColor,
  }) {
    final serviceEnabled = _locationState?.serviceEnabled ?? false;
    final permissionGranted = _locationState?.isPermissionGranted ?? false;
    final position = _locationState?.position;

    return SigmaCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isReady
                      ? Colors.green.withValues(alpha: 0.14)
                      : (isDark
                            ? AppTheme.accentGold.withValues(alpha: 0.15)
                            : AppTheme.primary.withValues(alpha: 0.09)),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  isReady
                      ? Icons.my_location_rounded
                      : Icons.location_on_rounded,
                  size: 20,
                  color: isReady
                      ? Colors.green
                      : (isDark ? AppTheme.accentGold : AppTheme.primary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Geolocalización requerida',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      isReady
                          ? 'Ubicación verificada y lista para operar'
                          : 'Requisito obligatorio para habilitar el sistema',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isReady ? Colors.green : subtitleColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Estado paso a paso
          if (_isChecking)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            )
          else ...[
            _StatusRow(
              icon: Icons.gps_fixed_rounded,
              title: 'Servicio GPS del dispositivo',
              subtitle: serviceEnabled
                  ? 'Encendido y disponible'
                  : 'Desactivado en el dispositivo',
              isOk: serviceEnabled,
              isDark: isDark,
              trailingAction: !serviceEnabled
                  ? TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: _locationService.openLocationSettings,
                      child: const Text('Encender'),
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            _StatusRow(
              icon: Icons.verified_user_outlined,
              title: 'Permiso de ubicación SIGMA',
              subtitle: permissionGranted
                  ? 'Autorizado correctamente'
                  : (_locationState?.isDeniedForever == true
                        ? 'Bloqueado — requiere abrir ajustes'
                        : 'Pendiente de autorización'),
              isOk: permissionGranted,
              isDark: isDark,
              trailingAction:
                  (!permissionGranted &&
                      _locationState?.isDeniedForever == true)
                  ? TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: _locationService.openAppSettings,
                      child: const Text('Ajustes'),
                    )
                  : null,
            ),
            if (isReady && position != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.30),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.pin_drop_outlined,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Coordenadas: '
                        '${position.latitude.toStringAsFixed(5)}, '
                        '${position.longitude.toStringAsFixed(5)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.green.shade300
                              : Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          if (_feedbackMessage != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _isFeedbackError
                    ? Colors.amber.withValues(alpha: 0.14)
                    : Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isFeedbackError
                      ? Colors.amber.withValues(alpha: 0.45)
                      : Colors.green.withValues(alpha: 0.40),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isFeedbackError
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 18,
                    color: _isFeedbackError
                        ? Colors.amber.shade700
                        : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _feedbackMessage!,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _isFeedbackError
                            ? (isDark
                                  ? Colors.amber.shade200
                                  : Colors.amber.shade900)
                            : (isDark
                                  ? Colors.green.shade300
                                  : Colors.green.shade800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          if (!isReady) ...[
            SigmaPrimaryButton(
              label: 'Activar geolocalización',
              loadingLabel: 'Verificando ubicación...',
              icon: Icons.my_location_rounded,
              height: 44,
              isLoading: _isRequesting,
              onPressed: _handleActivateLocation,
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(fontSize: 12.5),
              ),
              onPressed: _isRequesting ? null : _refreshLocationStatus,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Ya la activé, volver a comprobar'),
            ),
          ] else ...[
            SigmaPrimaryButton(
              label: 'Continuar al Panel Principal',
              loadingLabel: 'Ingresando...',
              icon: Icons.arrow_forward_rounded,
              height: 44,
              isLoading: _isCompleting,
              onPressed: _handleContinueToDashboard,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeaturesCard({
    required bool isDark,
    required Color titleColor,
    required Color subtitleColor,
  }) {
    return SigmaCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Para qué se utiliza tu ubicación en SIGMA?',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 8),
          _FeaturePoint(
            icon: Icons.route_rounded,
            color: const Color(0xFF2563EB),
            title: 'Control de salidas y rutas',
            description:
                'Validación geográfica en partida, destino e inspecciones.',
            titleColor: titleColor,
            subtitleColor: subtitleColor,
          ),
          const SizedBox(height: 7),
          _FeaturePoint(
            icon: Icons.directions_car_rounded,
            color: const Color(0xFF0F766E),
            title: 'Gestión de flota vehicular',
            description: 'Trazabilidad de unidades asignadas y asistencia.',
            titleColor: titleColor,
            subtitleColor: subtitleColor,
          ),
          const SizedBox(height: 7),
          _FeaturePoint(
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFD97706),
            title: 'Reportes e incidentes en campo',
            description: 'Georreferenciación de mantenimientos y novedades.',
            titleColor: titleColor,
            subtitleColor: subtitleColor,
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isOk;
  final bool isDark;
  final Widget? trailingAction;

  const _StatusRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isOk,
    required this.isDark,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isOk ? Colors.green : Colors.orange;
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : const Color(0xFFF8FAFC);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: isOk
              ? Colors.green.withValues(alpha: 0.35)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOk ? Icons.check_circle_rounded : icon,
            color: statusColor,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF172B4D),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          ?trailingAction,
        ],
      ),
    );
  }
}

class _FeaturePoint extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final Color titleColor;
  final Color subtitleColor;

  const _FeaturePoint({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.titleColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 15),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: subtitleColor,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
