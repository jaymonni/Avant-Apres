import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

class AppStrings {
  static const Map<String, Map<String, String>> _localized = {
    'fr': {
      'appName': 'Avant / Après',
    },
    'en': {
      'appName': 'Before / After',
    },
  };

  static String of(Locale locale, String key) {
    final language = _localized[locale.languageCode] ?? _localized['fr']!;
    return language[key] ?? key;
  }
}

class AvantApresApp extends StatelessWidget {
  const AvantApresApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final locale = themeController.currentLocale;

    return MaterialApp(
      title: AppStrings.of(locale, 'appName'),
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildAppTheme(themeController.palette),
      home: const HomeScreen(),
    );
  }
}
