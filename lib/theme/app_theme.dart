import 'package:flutter/material.dart';

import 'palette.dart';

class AppTheme {
  static ThemeData light(AppPalette palette) {
    final isDark = palette.type == AppPaletteType.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: palette.primary,
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: palette.primary,
      secondary: palette.secondary,
      surface: palette.card,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      cardColor: palette.card,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      useMaterial3: true,
    );
  }
}
