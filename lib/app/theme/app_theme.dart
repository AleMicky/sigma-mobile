import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier de Riverpod para controlar el modo de tema (Claro / Oscuro / Sistema).
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void toggle(Brightness currentBrightness) {
    state = currentBrightness == Brightness.dark
        ? ThemeMode.light
        : ThemeMode.dark;
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF0A2458);
  static const Color secondary = Color(0xFF2563EB);
  static const Color accentGold = Color(0xFFE5B800);
  static const Color background = Color(0xFFF4F7FB);
  static const Color darkBackground = Color(0xFF0A1120);
  static const Color darkSurface = Color(0xFF131E33);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 60,
        backgroundColor: Colors.white,
        indicatorColor: secondary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      surface: darkSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: Colors.white,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 60,
        backgroundColor: darkSurface,
        indicatorColor: accentGold.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
