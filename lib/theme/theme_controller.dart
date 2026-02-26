import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'palette.dart';

class ThemeController extends ChangeNotifier {
  static const String _paletteKey = 'palette_v1';
  static const String _localeKey = 'locale_v1';

  AppPaletteType _paletteType = AppPaletteType.blue;
  Locale _currentLocale = const Locale('fr');

  AppPalette get palette => AppPalette.fromType(_paletteType);
  AppPaletteType get paletteType => _paletteType;
  Locale get currentLocale => _currentLocale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final paletteName = prefs.getString(_paletteKey) ?? AppPaletteType.blue.name;
    _paletteType = AppPaletteType.values.firstWhere(
      (item) => item.name == paletteName,
      orElse: () => AppPaletteType.blue,
    );

    final localeCode = prefs.getString(_localeKey) ?? 'fr';
    _currentLocale = Locale(localeCode);
    notifyListeners();
  }

  Future<void> setPalette(AppPaletteType type) async {
    _paletteType = type;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_paletteKey, type.name);
  }

  Future<void> setLocale(Locale locale) async {
    _currentLocale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }
}
