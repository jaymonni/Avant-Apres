import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'palette.dart';

class ThemeController extends ChangeNotifier {
  static const String _paletteKey = 'palette_v1';
  static const String _localeKey = 'locale_v1';
  static const String _hasChosenLocaleKey = 'has_chosen_locale_v1';

  AppPalette _palette = AppPalettes.blue;
  Locale _currentLocale = const Locale('en');
  bool _hasChosenLocale = false;

  AppPalette get palette => _palette;
  Locale get currentLocale => _currentLocale;
  bool get hasChosenLocale => _hasChosenLocale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final paletteKey = prefs.getString(_paletteKey) ?? AppPalettes.blue.key;
    _palette = AppPalettes.byKey(paletteKey);

    final localeCode = prefs.getString(_localeKey);
    _hasChosenLocale = prefs.getBool(_hasChosenLocaleKey) ?? false;

    if (localeCode != null && localeCode.trim().isNotEmpty) {
      _currentLocale = Locale(localeCode);
    } else {
      _currentLocale = const Locale('en');
    }

    notifyListeners();
  }

  Future<void> setPalette(AppPalette palette) async {
    _palette = palette;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_paletteKey, palette.key);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _currentLocale = locale;
    _hasChosenLocale = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
    await prefs.setBool(_hasChosenLocaleKey, true);

    notifyListeners();
  }
}