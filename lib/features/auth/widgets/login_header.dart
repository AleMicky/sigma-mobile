import 'package:flutter/material.dart';
import 'package:sigma_mobile/app/theme/app_theme.dart';
import 'package:sigma_mobile/core/widgets/sigma_widgets.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 360 || size.height < 700;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isCompact ? 12 : 16,
        horizontal: isCompact ? 14 : 18,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF13223E), const Color(0xFF0D172A)]
              : [Colors.white, const Color(0xFFF8FAFF)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.30)
                : AppTheme.primary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo institucional reutilizable ENDE CORANI (Normal / Dark)
          SigmaBrandLogo(height: isCompact ? 48 : 56),
          SizedBox(height: isCompact ? 8 : 12),
          // Línea divisoria con acento dorado institucional
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Container(
                  width: isCompact ? 20 : 28,
                  height: 1.8,
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
              ),
              SizedBox(width: isCompact ? 6 : 8),
              Flexible(
                flex: 3,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 8 : 12,
                    vertical: 3.5,
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
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isCompact ? 9.5 : 10.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppTheme.accentGold : AppTheme.primary,
                      letterSpacing: isCompact ? 1.0 : 1.5,
                    ),
                  ),
                ),
              ),
              SizedBox(width: isCompact ? 6 : 8),
              Flexible(
                child: Container(
                  width: isCompact ? 20 : 28,
                  height: 1.8,
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
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Gestión de Activos, Mantenimiento y Vehículos',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
