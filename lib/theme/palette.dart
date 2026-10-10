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
    gradA: Color(0xFF1976D2),
    gradB: Color(0xFF64B5F6),
    background: Color(0xFFF5F9FF),
    primary: Color(0xFF1565C0),
    secondary: Color(0xFF42A5F5),
    card: Colors.white,
  );

  static const green = AppPalette(
    key: 'green',
    gradA: Color(0xFF2E7D32),
    gradB: Color(0xFF81C784),
    background: Color(0xFFF4FBF4),
    primary: Color(0xFF2E7D32),
    secondary: Color(0xFF66BB6A),
    card: Colors.white,
  );

  static const pink = AppPalette(
    key: 'pink',
    gradA: Color(0xFFC2185B),
    gradB: Color(0xFFF48FB1),
    background: Color(0xFFFFF6FA),
    primary: Color(0xFFC2185B),
    secondary: Color(0xFFEC407A),
    card: Colors.white,
  );

  static const dark = AppPalette(
    key: 'dark',
    gradA: Color(0xFF111827),
    gradB: Color(0xFF374151),
    background: Color(0xFF0B1220),
    primary: Color(0xFFE5E7EB),
    secondary: Color(0xFF9CA3AF),
    card: Color(0xFF111827),
  );

  static const values = [blue, green, pink, dark];

  static AppPalette byKey(String key) {
    return values.firstWhere(
      (palette) => palette.key == key,
      orElse: () => blue,
    );
  }
}