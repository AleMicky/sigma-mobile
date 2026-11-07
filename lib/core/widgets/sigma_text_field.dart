import 'package:flutter/material.dart';
import 'package:sigma_mobile/app/theme/app_theme.dart';

/// Campo de texto institucional reutilizable en toda la aplicación SIGMA.
/// Se adapta automáticamente a modo claro y oscuro.
class SigmaTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;
  final int maxLines;

  const SigmaTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.enabled = true,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF172B4D);
    final labelColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final fillColor = isDark
        ? const Color(0xFF0E1729)
        : const Color(0xFFF8FAFC);
    final borderColor = isDark
        ? const Color(0xFF26354D)
        : const Color(0xFFD8E1EC);
    final focusColor = isDark ? AppTheme.accentGold : AppTheme.primary;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      maxLines: obscureText ? 1 : maxLines,
      style: TextStyle(
        fontSize: 14,
        color: textColor,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        labelStyle: TextStyle(color: labelColor, fontSize: 13),
        floatingLabelStyle: TextStyle(
          color: focusColor,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: labelColor.withValues(alpha: 0.65),
          fontSize: 13,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: focusColor, size: 19)
            : null,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 38,
        ),
        suffixIcon: suffixIcon,
        suffixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 38,
        ),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: focusColor, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade500),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade600, width: 1.6),
        ),
      ),
    );
  }
}
