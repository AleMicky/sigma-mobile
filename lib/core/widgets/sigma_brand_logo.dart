import 'package:flutter/material.dart';
import 'package:sigma_mobile/app/theme/app_theme.dart';

/// Logo institucional de ENDE CORANI que cambia automáticamente entre su versión
/// normal (`logo-ende-corani.png`) y su versión oscura (`logo-ende-corani-dark.png`).
class SigmaBrandLogo extends StatelessWidget {
  final double height;

  const SigmaBrandLogo({super.key, this.height = 60});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoAsset = isDark
        ? 'assets/logo-ende-corani-dark.png'
        : 'assets/logo-ende-corani.png';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: Image.asset(
        logoAsset,
        key: ValueKey(logoAsset),
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }
}

/// Estado vacío institucional reutilizable para listas o módulos sin registros.
class SigmaEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const SigmaEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 32,
                color: isDark ? AppTheme.accentGold : Colors.blueGrey,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF172B4D),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : Colors.grey.shade600,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
