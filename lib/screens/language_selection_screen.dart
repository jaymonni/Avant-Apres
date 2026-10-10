import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/theme_controller.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  Future<void> _selectLanguage(BuildContext context, Locale locale) async {
    await context.read<ThemeController>().setLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget languageButton({
      required String title,
      required String subtitle,
      required Locale locale,
    }) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          onTap: () => _selectLanguage(context, locale),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.language_rounded,
                size: 46,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 18),
              Text(
                'Choose your language',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Vous pourrez modifier ce choix plus tard dans les réglages.',
                style: TextStyle(
                  fontSize: 15,
                  color: colorScheme.onSurface.withValues(alpha: 0.70),
                ),
              ),
              const SizedBox(height: 24),
              languageButton(
                title: 'Français',
                subtitle: 'Utiliser l’application en français',
                locale: const Locale('fr'),
              ),
              languageButton(
                title: 'English',
                subtitle: 'Use the app in English',
                locale: const Locale('en'),
              ),
              languageButton(
                title: 'Español',
                subtitle: 'Usar la aplicación en español',
                locale: const Locale('es'),
              ),
              languageButton(
                title: 'Português',
                subtitle: 'Usar o aplicativo em português',
                locale: const Locale('pt'),
              ),
              const Spacer(),
              Text(
                'Avant / Après',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}