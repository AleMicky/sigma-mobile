import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sigma_mobile/app/theme/app_theme.dart';
import 'package:sigma_mobile/core/widgets/sigma_widgets.dart';
import 'package:sigma_mobile/features/auth/auth_service.dart';
import 'package:sigma_mobile/features/auth/widgets/login_footer.dart';
import 'package:sigma_mobile/features/auth/widgets/login_form_card.dart';
import 'package:sigma_mobile/features/auth/widgets/login_header.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      await AuthService.instance.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      _passwordController.clear();

      // GoRouter detecta el cambio de autenticación
      // y redirige automáticamente al Dashboard.
    } on DioException catch (error) {
      if (!mounted) return;
      _showError(_mapDioError(error));
    } catch (_) {
      if (!mounted) return;
      _showError('Error al iniciar sesión');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _mapDioError(DioException error) {
    if (error.response?.statusCode == 401) {
      return 'Usuario o contraseña incorrectos';
    }
    if (error.response?.statusCode == 403) {
      return 'No tienes permisos para acceder';
    }
    if (error.type == DioExceptionType.connectionTimeout) {
      return 'Tiempo de conexión agotado';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'No se pudo conectar con SIGMA API';
    }
    return 'No se pudo iniciar sesión';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 360 || size.height < 700;

    return Scaffold(
      body: Stack(
        children: [
          // Decoración ambiental institucional de fondo
          Positioned(
            top: -110,
            right: -80,
            child: IgnorePointer(
              child: Container(
                width: 280,
                height: 280,
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
            bottom: -120,
            left: -90,
            child: IgnorePointer(
              child: Container(
                width: 300,
                height: 300,
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
                // Barra superior con botón para alternar modo Normal / Dark
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isCompact ? 14 : 20,
                    6,
                    isCompact ? 14 : 20,
                    0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [ThemeToggleButton()],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 14 : 20,
                        vertical: 8,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 380),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const LoginHeader(),
                            const SizedBox(height: 12),
                            LoginFormCard(
                              formKey: _formKey,
                              usernameController: _usernameController,
                              passwordController: _passwordController,
                              isLoading: _loading,
                              onSubmit: _login,
                            ),
                            const SizedBox(height: 12),
                            const LoginFooter(),
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
}
