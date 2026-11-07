import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sigma_mobile/app/theme/app_theme.dart';

/// Botón reutilizable para alternar entre Modo Claro y Modo Oscuro.
///
/// Soporta dos variantes:
/// - [compact] = false (por defecto): Píldora con ícono y texto ("Modo claro" / "Modo oscuro").
/// - [compact] = true: Solo botón circular con ícono (ideal para AppBars o cabeceras).
class ThemeToggleButton extends ConsumerWidget {
  final bool compact;

  const ThemeToggleButton({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    if (compact) {
      return IconButton(
        tooltip: isDark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
        onPressed: () =>
            ref.read(themeModeProvider.notifier).toggle(brightness),
        icon: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          color: isDark ? AppTheme.accentGold : Colors.white,
        ),
      );
    }

    return Material(
      color: isDark
          ? AppTheme.darkSurface
          : Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => ref.read(themeModeProvider.notifier).toggle(brightness),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                size: 16,
                color: isDark ? AppTheme.accentGold : AppTheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                isDark ? 'Modo claro' : 'Modo oscuro',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
