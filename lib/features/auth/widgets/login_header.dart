import 'package:flutter/material.dart';
import 'package:sigma_mobile/app/theme/app_theme.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoAsset = isDark
        ? 'assets/logo-ende-corani-dark.png'
        : 'assets/logo-ende-corani.png';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF13223E), const Color(0xFF0D172A)]
              : [Colors.white, const Color(0xFFF8FAFF)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : AppTheme.primary.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo institucional ENDE CORANI (Normal / Dark)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: Image.asset(
              logoAsset,
              key: ValueKey(logoAsset),
              height: 84,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 20),
          // Línea divisoria con acento dorado institucional
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentGold.withValues(alpha: 0.0),
                      AppTheme.accentGold,
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.accentGold.withValues(alpha: 0.14)
                      : AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? AppTheme.accentGold.withValues(alpha: 0.35)
                        : AppTheme.primary.withValues(alpha: 0.14),
                  ),
                ),
                child: Text(
                  'PLATAFORMA SIGMA',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppTheme.accentGold : AppTheme.primary,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 36,
                height: 2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentGold,
                      AppTheme.accentGold.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Gestión de Activos, Mantenimiento y Vehículos',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
