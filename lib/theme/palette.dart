import 'package:flutter/material.dart';

class AppPalette {
  const AppPalette({
    required this.key,
    required this.gradA,
    required this.gradB,
    required this.background,
    required this.primary,
    required this.secondary,
    required this.card,
  });

  final String key;
  final Color gradA;
  final Color gradB;
  final Color background;
  final Color primary;
  final Color secondary;
  final Color card;
}

class AppPalettes {
  static const blue = AppPalette(
    key: 'blue',
    gradA: Color(0xFF477F99),
    gradB: Color(0xFF8CB9C4),
    background: Color(0xFFF4F8F9),
    primary: Color(0xFF39778D),
    secondary: Color(0xFF6D9FAE),
    card: Colors.white,
  );

  static const green = AppPalette(
    key: 'green',
    gradA: Color(0xFF557D66),
    gradB: Color(0xFF9BB9A2),
    background: Color(0xFFF5F8F4),
    primary: Color(0xFF557D66),
    secondary: Color(0xFF779982),
    card: Colors.white,
  );

  static const pink = AppPalette(
    key: 'pink',
    gradA: Color(0xFFA95373),
    gradB: Color(0xFFE0A5B6),
    background: Color(0xFFFCF6F8),
    primary: Color(0xFFA95373),
    secondary: Color(0xFFC77F91),
    card: Colors.white,
  );

  static const dark = AppPalette(
    key: 'dark',
    gradA: Color(0xFF333945),
    gradB: Color(0xFF555963),
    background: Color(0xFF171B23),
    primary: Color(0xFFE1E4E8),
    secondary: Color(0xFFB0B5BD),
    card: Color(0xFF333945),
  );

  static const values = [blue, green, pink, dark];

  static AppPalette byKey(String key) {
    return values.firstWhere(
      (palette) => palette.key == key,
      orElse: () => blue,
    );
  }
}