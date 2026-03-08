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
    required this.card,
  });

  final AppPaletteType type;
  final Color gradA;
  final Color gradB;
  final Color background;
  final Color primary;
  final Color secondary;
  final Color card;

  static const blue = AppPalette(
    type: AppPaletteType.blue,
    gradA: Color(0xFF4A90E2),
    gradB: Color(0xFF50E3C2),
    background: Color(0xFFF3F7FC),
    primary: Color(0xFF1A73E8),
    secondary: Color(0xFF00A8B5),
    card: Color(0xFFFFFFFF),
  );

  static const green = AppPalette(
    type: AppPaletteType.green,
    gradA: Color(0xFF4CAF50),
    gradB: Color(0xFFAED581),
    background: Color(0xFFF4FAF2),
    primary: Color(0xFF2E7D32),
    secondary: Color(0xFF66BB6A),
    card: Color(0xFFFFFFFF),
  );

  static const pink = AppPalette(
    type: AppPaletteType.pink,
    gradA: Color(0xFFE91E63),
    gradB: Color(0xFFFF8A80),
    background: Color(0xFFFFF3F8),
    primary: Color(0xFFC2185B),
    secondary: Color(0xFFFF5C8D),
    card: Color(0xFFFFFFFF),
  );

  static const dark = AppPalette(
    type: AppPaletteType.dark,
    gradA: Color(0xFF2E2E2E),
    gradB: Color(0xFF616161),
    background: Color(0xFF121212),
    primary: Color(0xFF222222),
    secondary: Color(0xFF424242),
    card: Color(0xFF1F1F1F),
  );

  static List<AppPalette> all = [blue, green, pink, dark];

  static AppPalette byType(AppPaletteType type) {
    return all.firstWhere((p) => p.type == type, orElse: () => blue);
  }
}
