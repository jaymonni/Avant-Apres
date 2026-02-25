import 'package:flutter/material.dart';

enum AppPaletteType { blue, green, pink, dark }

class AppPalette {
  const AppPalette({
    required this.type,
    required this.gradA,
    required this.gradB,
    required this.background,
    required this.primary,
    required this.secondary,
  });

  final AppPaletteType type;
  final Color gradA;
  final Color gradB;
  final Color background;
  final Color primary;
  final Color secondary;

  static AppPalette fromType(AppPaletteType type) {
    switch (type) {
      case AppPaletteType.green:
        return const AppPalette(
          type: AppPaletteType.green,
          gradA: Color(0xFF5CCB8A),
          gradB: Color(0xFF1B8B5F),
          background: Color(0xFFF1FFF7),
          primary: Color(0xFF1B8B5F),
          secondary: Color(0xFF2BB673),
        );
      case AppPaletteType.pink:
        return const AppPalette(
          type: AppPaletteType.pink,
          gradA: Color(0xFFF783B7),
          gradB: Color(0xFFC95188),
          background: Color(0xFFFFF3F8),
          primary: Color(0xFFC95188),
          secondary: Color(0xFFE36AA0),
        );
      case AppPaletteType.dark:
        return const AppPalette(
          type: AppPaletteType.dark,
          gradA: Color(0xFF3C3F46),
          gradB: Color(0xFF1C1E24),
          background: Color(0xFF111217),
          primary: Color(0xFFECECEC),
          secondary: Color(0xFF9FA4B3),
        );
      case AppPaletteType.blue:
        return const AppPalette(
          type: AppPaletteType.blue,
          gradA: Color(0xFF73B7FF),
          gradB: Color(0xFF3A6AE3),
          background: Color(0xFFF0F6FF),
          primary: Color(0xFF2B55CC),
          secondary: Color(0xFF4E7AF2),
        );
    }
  }
}
