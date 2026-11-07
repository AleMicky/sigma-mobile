import 'package:flutter/material.dart';

/// Encabezado de sección reutilizable con botón de acción opcional.
class SigmaSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SigmaSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF172B4D),
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}
