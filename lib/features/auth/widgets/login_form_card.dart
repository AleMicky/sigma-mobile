import 'package:flutter/material.dart';
import 'package:sigma_mobile/app/theme/app_theme.dart';
import 'package:sigma_mobile/core/config/app_config.dart';
import 'package:sigma_mobile/core/widgets/sigma_widgets.dart';
import 'package:sigma_mobile/features/settings/api_config_page.dart';

class LoginFormCard extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onSubmit;

  const LoginFormCard({
    super.key,
    required this.formKey,
    required this.usernameController,
    required this.passwordController,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  State<LoginFormCard> createState() => _LoginFormCardState();
}

class _LoginFormCardState extends State<LoginFormCard> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 360 || size.height < 700;

    final titleColor = isDark ? Colors.white : const Color(0xFF172B4D);
    final subtitleColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return SigmaCard(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      borderRadius: 18,
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.accentGold.withValues(alpha: 0.14)
                        : AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.lock_person_rounded,
                    size: 18,
                    color: isDark ? AppTheme.accentGold : AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Iniciar sesión',
                        style: TextStyle(
                          fontSize: isCompact ? 17 : 18.5,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                      ),
                      Text(
                        'Credenciales institucionales',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: subtitleColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Configurar URL de API',
                  visualDensity: VisualDensity.compact,
                  onPressed: widget.isLoading
                      ? null
                      : () => showApiConfigSheet(context),
                  icon: Icon(
                    Icons.settings_ethernet_rounded,
                    size: 20,
                    color: isDark ? AppTheme.accentGold : AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SigmaTextField(
              controller: widget.usernameController,
              label: 'Usuario',
              hint: 'Ej. jperez',
              prefixIcon: Icons.person_outline_rounded,
              enabled: !widget.isLoading,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa tu usuario';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            SigmaTextField(
              controller: widget.passwordController,
              label: 'Contraseña',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              enabled: !widget.isLoading,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => widget.onSubmit(),
              suffixIcon: IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: _obscurePassword
                    ? 'Mostrar contraseña'
                    : 'Ocultar contraseña',
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 19,
                  color: subtitleColor,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa tu contraseña';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            SigmaPrimaryButton(
              label: 'Ingresar a SIGMA',
              loadingLabel: 'Iniciando sesión...',
              icon: Icons.login_rounded,
              height: 44,
              isLoading: widget.isLoading,
              onPressed: widget.onSubmit,
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder<String>(
              valueListenable: AppConfig.apiBaseUrlNotifier,
              builder: (context, currentUrl, _) {
                final isCustom = AppConfig.isCustomUrl;
                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: widget.isLoading
                      ? null
                      : () => showApiConfigSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0E1729)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF26354D)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.dns_outlined,
                          size: 14,
                          color: isDark
                              ? AppTheme.accentGold
                              : AppTheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isCustom
                                ? 'Servidor SIGMA (Personalizado)'
                                : 'Servidor SIGMA conectado',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: subtitleColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Configurar',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppTheme.accentGold
                                : AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
