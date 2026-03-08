import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'palette.dart';

class ThemeController extends ChangeNotifier {
  static const _paletteKey = 'palette_v1';
  static const _localeKey = 'locale_v1';

  AppPaletteType _currentType = AppPaletteType.blue;
  Locale _currentLocale = const Locale('fr');

  AppPalette get currentPalette => AppPalette.byType(_currentType);
  Locale get currentLocale => _currentLocale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final paletteName = prefs.getString(_paletteKey);
    final localeCode = prefs.getString(_localeKey);

    if (paletteName != null) {
      _currentType = AppPaletteType.values.firstWhere(
        (e) => e.name == paletteName,
        orElse: () => AppPaletteType.blue,
      );
    }

    if (localeCode != null && localeCode.isNotEmpty) {
      _currentLocale = Locale(localeCode);
    }
    notifyListeners();
  }

  Future<void> setPalette(AppPaletteType type) async {
    _currentType = type;
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
