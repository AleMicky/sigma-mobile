import 'package:flutter/material.dart';
import 'package:sigma_mobile/app/theme/app_theme.dart';

class VehiculoThumb extends StatelessWidget {
  final String? urlImagen;
  final double size;
  final double borderRadius;

  const VehiculoThumb({
    super.key,
    this.urlImagen,
    this.size = 38,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final hasImg = urlImagen != null && urlImagen!.trim().isNotEmpty;
    if (hasImg) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          urlImagen!.trim(),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: const Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
              ),
            );
          },
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0284C7).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.directions_car_rounded,
        size: size * 0.54,
        color: const Color(0xFF0284C7),
      ),
    );
  }
}

class PlacaBadge extends StatelessWidget {
  final String placa;
  final bool compact;

  const PlacaBadge({
    super.key,
    required this.placa,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    if (placa.trim().isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 1.5 : 2.5,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
          width: 0.9,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 3,
            height: compact ? 9 : 11,
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            placa.toUpperCase(),
            style: TextStyle(
              fontSize: compact ? 10.5 : 11.5,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
              letterSpacing: 0.6,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

class TipoVehiculoBadge extends StatelessWidget {
  final String tipo;
  final bool compact;

  const TipoVehiculoBadge({
    super.key,
    required this.tipo,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    if (tipo.trim().isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 7,
        vertical: compact ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha: isDark ? 0.2 : 0.10),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tipo.toUpperCase(),
        style: TextStyle(
          fontSize: compact ? 9 : 10,
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFF38BDF8) : AppTheme.secondary,
        ),
      ),
    );
  }
}

