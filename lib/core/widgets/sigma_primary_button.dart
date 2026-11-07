import 'package:flutter/material.dart';
import 'package:sigma_mobile/app/theme/app_theme.dart';

/// Botón primario institucional reutilizable con soporte de estado de carga (loading)
/// y adaptación automática al tema Claro / Oscuro.
class SigmaPrimaryButton extends StatelessWidget {
  final String label;
  final String? loadingLabel;
  final IconData? icon;
  final bool isLoading;
  final VoidCallback? onPressed;
  final double height;

  const SigmaPrimaryButton({
    super.key,
    required this.label,
    this.loadingLabel,
    this.icon,
    this.isLoading = false,
    this.onPressed,
    this.height = 46,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonBg = isDark ? AppTheme.accentGold : AppTheme.primary;
    final buttonFg = isDark ? const Color(0xFF0A1931) : Colors.white;

    return SizedBox(
      height: height,
      child: FilledButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: buttonBg,
          foregroundColor: buttonFg,
          disabledBackgroundColor: buttonBg.withValues(alpha: 0.55),
          disabledForegroundColor: buttonFg.withValues(alpha: 0.8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        icon: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: buttonFg,
                ),
              )
            : (icon != null ? Icon(icon, size: 19) : const SizedBox.shrink()),
        label: Text(isLoading ? (loadingLabel ?? label) : label),
      ),
    );
  }
}
