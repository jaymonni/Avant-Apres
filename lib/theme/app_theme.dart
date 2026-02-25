import 'package:flutter/material.dart';

import 'palette.dart';

ThemeData buildAppTheme(AppPalette palette) {
  final isDark = palette.type == AppPaletteType.dark;

  return ThemeData(
    useMaterial3: true,
    brightness: isDark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: palette.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: palette.primary,
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: palette.primary,
      secondary: palette.secondary,
      surface: palette.background,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.background,
      foregroundColor: palette.primary,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: isDark ? const Color(0xFF23252D) : Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.secondary.withValues(alpha: 0.4)),
      ),
    ),
  );
}
