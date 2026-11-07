import 'package:flutter/material.dart';
import 'package:sigma_mobile/app/theme/app_theme.dart';

/// Tarjeta contenedora institucional con bordes suaves y sombra adaptable a Modo Claro/Oscuro.
class SigmaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;

  const SigmaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;

    final container = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
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
                : const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return container;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: container,
      ),
    );
  }
}
