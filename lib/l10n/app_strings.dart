import 'package:flutter/widgets.dart';

class AppStrings {
  AppStrings(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('fr'), Locale('en')];

  static const LocalizationsDelegate<AppStrings> delegate =
      _AppStringsDelegate();

  static const Map<String, Map<String, String>> _localizedValues = {
    'fr': {
      'appName': 'Avant / Après',
      'inProgress': 'Projets en cours',
      'done': 'Mes projets',
      'newProject': 'Nouveau',
      'settings': 'Réglages',
      'title': 'Titre',
      'description': 'Description',
      'save': 'Enregistrer',
      'complete': 'Compléter',
      'deleteConfirm': 'Voulez-vous supprimer ce projet ?',
      'cancel': 'Annuler',
      'delete': 'Supprimer',
      'open': 'Ouvrir',
      'favorite': 'Favori',
      'unfavorite': 'Retirer favori',
      'before': 'Avant',
      'during': 'Pendant',
      'after': 'Après',
      'brokenImage': 'image cassée',
      'missingImage': 'image manquante',
      'palette': 'Palette',
      'list': 'Liste',
      'grid': 'Grille',
    },
    'en': {
      'appName': 'Before / After',
      'inProgress': 'In progress projects',
      'done': 'My projects',
      'newProject': 'New',
      'settings': 'Settings',
      'title': 'Title',
      'description': 'Description',
      'save': 'Save',
      'complete': 'Complete',
      'deleteConfirm': 'Do you want to delete this project?',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'open': 'Open',
      'favorite': 'Favorite',
      'unfavorite': 'Remove favorite',
      'before': 'Before',
      'during': 'During',
      'after': 'After',
      'brokenImage': 'broken image',
      'missingImage': 'missing image',
      'palette': 'Palette',
      'list': 'List',
      'grid': 'Grid',
    },
  };

  static AppStrings of(BuildContext context) {
    final strings = Localizations.of<AppStrings>(context, AppStrings);
    return strings ?? AppStrings(const Locale('fr'));
  }

  String t(String key) {
    final lang = _localizedValues[locale.languageCode] ?? _localizedValues['fr']!;
    return lang[key] ?? key;
  }
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppStrings.supportedLocales.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppStrings> load(Locale locale) async => AppStrings(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppStrings> old) => false;
}
