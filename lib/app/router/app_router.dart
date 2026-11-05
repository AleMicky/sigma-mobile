import 'package:go_router/go_router.dart';
import 'package:sigma_mobile/features/dashboard/dashboard_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'dashboard',
      builder: (context, state) => const DashboardPage(),
    ),
  ],
);
