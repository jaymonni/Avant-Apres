import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../theme/palette.dart';
import '../theme/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final controller = context.watch<ThemeController>();

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(strings.t('palette'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          ...AppPalette.all.map((palette) {
            final selected = controller.currentPalette.type == palette.type;
            final indicatorColor = palette.type == AppPaletteType.dark
                ? Colors.black
                : Theme.of(context).colorScheme.primary;
            return Card(
              child: ListTile(
                onTap: () => controller.setPalette(palette.type),
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [palette.gradA, palette.gradB]),
                  ),
                ),
                title: Text(palette.type.name),
                trailing: selected
                    ? Icon(Icons.check_circle, color: indicatorColor)
                    : const SizedBox.shrink(),
              ),
            );
          }),
          const SizedBox(height: 14),
          DropdownButtonFormField<Locale>(
            value: controller.currentLocale,
            decoration: const InputDecoration(labelText: 'Langue'),
            items: const [
              DropdownMenuItem(value: Locale('fr'), child: Text('Français')),
              DropdownMenuItem(value: Locale('en'), child: Text('English')),
            ],
            onChanged: (value) {
              if (value != null) {
                controller.setLocale(value);
              }
            },
          ),
        ],
      ),
    );
  }
}
