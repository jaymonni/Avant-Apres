import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/palette.dart';
import '../theme/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Palette', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...AppPaletteType.values.map(
            (paletteType) => Card(
              child: ListTile(
                title: Text(_paletteLabel(paletteType)),
                trailing: _paletteIndicator(
                  context,
                  paletteType,
                  selected: paletteType == themeController.paletteType,
                ),
                onTap: () => themeController.setPalette(paletteType),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Langue (préparation EN)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<Locale>(
            segments: const [
              ButtonSegment(value: Locale('fr'), label: Text('FR')),
              ButtonSegment(value: Locale('en'), label: Text('EN')),
            ],
            selected: {themeController.currentLocale},
            onSelectionChanged: (value) {
              themeController.setLocale(value.first);
            },
          ),
        ],
      ),
    );
  }

  String _paletteLabel(AppPaletteType type) {
    switch (type) {
      case AppPaletteType.blue:
        return 'Bleu';
      case AppPaletteType.green:
        return 'Vert';
      case AppPaletteType.pink:
        return 'Rose';
      case AppPaletteType.dark:
        return 'Sombre';
    }
  }

  Widget _paletteIndicator(BuildContext context, AppPaletteType type, {required bool selected}) {
    if (!selected) {
      return const Icon(Icons.circle_outlined);
    }

    if (type == AppPaletteType.dark) {
      return const Icon(Icons.circle, color: Colors.black);
    }

    return Icon(Icons.circle, color: Theme.of(context).colorScheme.primary);
  }
}
