import 'package:go_router/go_router.dart';
import 'package:sigma_mobile/features/auth/auth_service.dart';
import 'package:sigma_mobile/features/auth/login_page.dart';
import 'package:sigma_mobile/features/dashboard/dashboard_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: AuthService.instance,
  redirect: (context, state) {
    final authenticated = AuthService.instance.isAuthenticated;

    final isLogin = state.matchedLocation == '/login';

    if (!authenticated) {
      return isLogin ? null : '/login';
    }

    if (isLogin) {
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
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
  ],
);
