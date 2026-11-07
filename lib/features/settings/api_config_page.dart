import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:sigma_mobile/app/theme/app_theme.dart';
import 'package:sigma_mobile/core/config/app_config.dart';
import 'package:sigma_mobile/core/widgets/sigma_widgets.dart';

/// Abre un panel modal inferior para configurar la URL de SIGMA API.
Future<void> showApiConfigSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => const _ApiConfigBottomSheet(),
  );
}

/// Página completa de configuración del servidor API.
class ApiConfigPage extends StatelessWidget {
  const ApiConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de API'),
        actions: const [ThemeToggleButton(compact: true), SizedBox(width: 8)],
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: ApiConfigForm(),
        ),
      ),
    );
  }
}

class _ApiConfigBottomSheet extends StatelessWidget {
  const _ApiConfigBottomSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 18 + bottomInset),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : AppTheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            ApiConfigForm(onSaved: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }
}

class ApiConfigForm extends StatefulWidget {
  final VoidCallback? onSaved;

  const ApiConfigForm({super.key, this.onSaved});

  @override
  State<ApiConfigForm> createState() => _ApiConfigFormState();
}

class _ApiConfigFormState extends State<ApiConfigForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlController;

  bool _isSaving = false;
  bool _isTesting = false;
  String? _testMessage;
  bool? _testSuccess;

  @override
  void initState() {
    super.initState();
    // Carga por defecto la URL que está usando actualmente (o la predeterminada)
    _urlController = TextEditingController(text: AppConfig.apiBaseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa la URL base de la API';
    }
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        (!uri.isScheme('http') && !uri.isScheme('https')) ||
        uri.host.isEmpty) {
      return 'Ingresa una URL válida (http:// o https://)';
    }
    return null;
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    final targetUrl = AppConfig.normalizeUrl(_urlController.text);

    setState(() {
      _isTesting = true;
      _testMessage = null;
      _testSuccess = null;
    });

    final testDio = Dio(
      BaseOptions(
        baseUrl: targetUrl,
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 6),
        headers: {'Accept': 'application/json'},
      ),
    );

    try {
      final response = await testDio.get(AppConfig.healthPath);
      if (!mounted) return;

      final isOk =
          response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;

      setState(() {
        _testSuccess = isOk;
        _testMessage = isOk
            ? 'Conexión exitosa con el servidor (/api/v1/health)'
            : 'El servidor respondió con estado HTTP ${response.statusCode}';
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _testSuccess = false;
        _testMessage = e.response != null
            ? 'Error en /api/v1/health (HTTP ${e.response?.statusCode})'
            : 'No se pudo conectar con el servidor (/api/v1/health)';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _testSuccess = false;
        _testMessage = 'Error al verificar la conexión con el servidor.';
      });
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      await AppConfig.setApiBaseUrl(_urlController.text);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración de servidor guardada correctamente'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      widget.onSaved?.call();
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _resetDefault() async {
    setState(() => _isSaving = true);
    try {
      await AppConfig.resetApiBaseUrl();
      _urlController.text = AppConfig.defaultApiBaseUrl;
      setState(() {
        _testMessage = null;
        _testSuccess = null;
      });
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se restauró la URL por defecto'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF172B4D);
    final subtitleColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return SigmaCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.accentGold.withValues(alpha: 0.14)
                        : AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.settings_ethernet_rounded,
                    color: isDark ? AppTheme.accentGold : AppTheme.primary,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configuración de API',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                      ),
                      Text(
                        'URL base del servidor SIGMA',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: subtitleColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SigmaTextField(
              controller: _urlController,
              label: 'URL Base de la API',
              hint: 'https://servidor-sigma/api/v1/',
              prefixIcon: Icons.link_rounded,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              validator: _validateUrl,
              onChanged: (_) {
                if (_testMessage != null) {
                  setState(() {
                    _testMessage = null;
                    _testSuccess = null;
                  });
                }
              },
            ),
            if (_testMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: (_testSuccess ?? false)
                      ? Colors.green.withValues(alpha: 0.12)
                      : Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (_testSuccess ?? false)
                        ? Colors.green.withValues(alpha: 0.4)
                        : Colors.red.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      (_testSuccess ?? false)
                          ? Icons.check_circle_outline_rounded
                          : Icons.error_outline_rounded,
                      size: 18,
                      color: (_testSuccess ?? false)
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testMessage!,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: (_testSuccess ?? false)
                              ? (isDark
                                    ? Colors.green.shade300
                                    : Colors.green.shade800)
                              : (isDark
                                    ? Colors.red.shade300
                                    : Colors.red.shade800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 310;
                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: (_isTesting || _isSaving)
                            ? null
                            : _testConnection,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: _isTesting
                            ? const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.wifi_tethering_rounded,
                                size: 17,
                              ),
                        label: Text(
                          _isTesting ? 'Probando...' : 'Probar conexión',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextButton.icon(
                        onPressed: (_isTesting || _isSaving)
                            ? null
                            : _resetDefault,
                        icon: const Icon(Icons.restore_rounded, size: 16),
                        label: const Text(
                          'Restaurar por defecto',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: (_isTesting || _isSaving)
                            ? null
                            : _testConnection,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: _isTesting
                            ? const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.wifi_tethering_rounded,
                                size: 17,
                              ),
                        label: Text(
                          _isTesting ? 'Probando...' : 'Probar conexión',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: (_isTesting || _isSaving)
                          ? null
                          : _resetDefault,
                      icon: const Icon(Icons.restore_rounded, size: 16),
                      label: const Text(
                        'Por defecto',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            SigmaPrimaryButton(
              label: 'Guardar configuración',
              loadingLabel: 'Guardando...',
              icon: Icons.save_rounded,
              height: 44,
              isLoading: _isSaving,
              onPressed: _saveConfig,
            ),
          ],
        ),
      ),
    );
  }
}
