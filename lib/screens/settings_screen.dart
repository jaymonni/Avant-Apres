import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../theme/palette.dart';
import '../theme/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _paletteLabel(String key, Locale locale) {
    final code = locale.languageCode;

    switch (key) {
      case 'blue':
        if (code == 'fr') return 'Bleu';
        if (code == 'es') return 'Azul';
        if (code == 'pt') return 'Azul';
        return 'Blue';
      case 'green':
        if (code == 'fr') return 'Vert';
        if (code == 'es') return 'Verde';
        if (code == 'pt') return 'Verde';
        return 'Green';
      case 'pink':
        if (code == 'fr') return 'Rose';
        if (code == 'es') return 'Rosa';
        if (code == 'pt') return 'Rosa';
        return 'Pink';
      case 'dark':
        if (code == 'fr') return 'Sombre';
        if (code == 'es') return 'Oscuro';
        if (code == 'pt') return 'Escuro';
        return 'Dark';
      default:
        return key;
    }
  }

  String _languageName(Locale locale) {
    switch (locale.languageCode) {
      case 'fr':
        return 'Français';
      case 'es':
        return 'Español';
      case 'pt':
        return 'Português';
      default:
        return 'English';
    }
  }

  Future<void> _rateApp(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final inAppReview = InAppReview.instance;

    try {
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      } else {
        await inAppReview.openStoreListing(
          appStoreId: '',
        );
      }
    } catch (_) {
      if (!context.mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode == 'fr'
                ? 'Impossible d’ouvrir la fiche Google Play.'
                : 'Unable to open the Google Play listing.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    final current = controller.palette;
    final locale = controller.currentLocale;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          Text(
            AppStrings.palette,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          ...AppPalettes.values.map(
            (palette) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                onTap: () => context.read<ThemeController>().setPalette(palette),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: [palette.gradA, palette.gradB],
                    ),
                  ),
                ),
                title: Text(
                  _paletteLabel(palette.key, locale),
                ),
                trailing: current.key == palette.key
                    ? Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppStrings.language,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(_languageName(locale)),
              leading: const Icon(Icons.language_rounded),
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _LanguageChip(locale: Locale('fr'), label: 'FR'),
              _LanguageChip(locale: Locale('en'), label: 'EN'),
              _LanguageChip(locale: Locale('es'), label: 'ES'),
              _LanguageChip(locale: Locale('pt'), label: 'PT'),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            AppStrings.rateApp,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              onTap: () => _rateApp(context),
              leading: Icon(
                Icons.star_rate_rounded,
                color: colorScheme.primary,
              ),
              title: Text(AppStrings.rateApp),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.locale,
    required this.label,
  });

  final Locale locale;
  final String label;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    final selected = controller.currentLocale.languageCode == locale.languageCode;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        context.read<ThemeController>().setLocale(locale);
      },
    );
  }
}