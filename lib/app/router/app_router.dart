import 'package:go_router/go_router.dart';
import 'package:sigma_mobile/features/auth/auth_service.dart';
import 'package:sigma_mobile/features/auth/login_page.dart';
import 'package:sigma_mobile/features/dashboard/dashboard_page.dart';
import 'package:sigma_mobile/features/onboarding/welcome_location_page.dart';
import 'package:sigma_mobile/features/porteria/porteria_page.dart';
import 'package:sigma_mobile/features/settings/api_config_page.dart';
import 'package:sigma_mobile/features/salida_vehicular/salida_vehicular_page.dart';
import 'package:sigma_mobile/features/solicitud_vehicular/solicitud_vehicular_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: AuthService.instance,
  redirect: (context, state) {
    final authenticated = AuthService.instance.isAuthenticated;
    final onboardingCompleted = AuthService.instance.hasCompletedOnboarding;

    final isLogin = state.matchedLocation == '/login';
    final isApiConfig = state.matchedLocation == '/settings/api';
    final isWelcome = state.matchedLocation == '/welcome';

    if (!authenticated) {
      return (isLogin || isApiConfig) ? null : '/login';
    }

    if (!onboardingCompleted) {
      return isWelcome ? null : '/welcome';
    }

    if (isLogin || isWelcome) {
      return '/';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      name: 'dashboard',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/welcome',
      name: 'welcome',
      builder: (context, state) => const WelcomeLocationPage(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/settings/api',
      name: 'api-config',
      builder: (context, state) => const ApiConfigPage(),
    ),
    GoRoute(
      path: '/porteria',
      name: 'porteria',
      builder: (context, state) => const PorteriaPage(),
    ),
    GoRoute(
      path: '/salidas-vehiculares',
      name: 'salidas-vehiculares',
      builder: (context, state) => const SalidaVehicularPage(),
    ),
    GoRoute(
      path: '/solicitudes-vehiculares',
      name: 'solicitudes-vehiculares',
      builder: (context, state) => const SolicitudVehicularPage(),
    ),
  ],
);
