import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:sigma_mobile/features/auth/auth_service.dart';
import 'package:sigma_mobile/features/auth/widgets/login_footer.dart';
import 'package:sigma_mobile/features/auth/widgets/login_form_card.dart';
import 'package:sigma_mobile/features/auth/widgets/login_header.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const LoginHeader(),
                  const SizedBox(height: 24),
                  LoginFormCard(
                    formKey: _formKey,
                    usernameController: _usernameController,
                    passwordController: _passwordController,
                    isLoading: _loading,
                    onSubmit: _login,
                  ),
                  const SizedBox(height: 28),
                  const LoginFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
