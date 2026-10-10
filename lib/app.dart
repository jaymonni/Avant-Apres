import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_strings.dart';
import 'screens/home_screen.dart';
import 'screens/language_selection_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

class AvantApresApp extends StatelessWidget {
  const AvantApresApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appTitle,
      locale: themeController.currentLocale,
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
        Locale('es'),
        Locale('pt'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: AppTheme.build(themeController.palette),
      builder: (context, child) {
        AppStrings.bindLocale(themeController.currentLocale);
        return child ?? const SizedBox.shrink();
      },
      home: themeController.hasChosenLocale
          ? const HomeScreen()
          : const LanguageSelectionScreen(),
    );
  }
}