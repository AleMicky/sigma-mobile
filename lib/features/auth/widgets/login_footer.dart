import 'package:flutter/material.dart';
import 'package:sigma_mobile/app/theme/app_theme.dart';

class LoginFooter extends StatelessWidget {
  const LoginFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF475569);
    final secondaryText = isDark
        ? const Color(0xFF64748B)
        : const Color(0xFF94A3B8);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_user_rounded,
                size: 16,
                color: isDark ? AppTheme.accentGold : AppTheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Sistema Institucional de Gestión',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: primaryText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Acceso exclusivo para personal autorizado • ENDE CORANI',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.5, color: secondaryText),
        ),
      ],
    );
  }
}
