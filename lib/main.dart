import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sigma_mobile/app/router/app_router.dart';
import 'package:sigma_mobile/app/theme/app_theme.dart';
import 'package:sigma_mobile/core/config/app_config.dart';
import 'package:sigma_mobile/features/auth/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppConfig.initialize();
  await AuthService.instance.initialize();

  runApp(const ProviderScope(child: SigmaApp()));
}

class SigmaApp extends ConsumerWidget {
  const SigmaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'SIGMA - ENDE CORANI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
