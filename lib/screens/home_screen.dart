import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../providers/app_provider.dart';
import '../theme/theme_controller.dart';
import 'add_project_screen.dart';
import 'project_list_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final palette = context.watch<ThemeController>().currentPalette;
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [palette.gradA.withValues(alpha: 0.12), palette.gradB.withValues(alpha: 0.12)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              strings.t('appName'),
              textAlign: TextAlign.center,
              style: GoogleFonts.pacifico(
                fontSize: 42,
                color: palette.primary,
              ),
            ),
            const SizedBox(height: 24),
            _BigCard(
              label: strings.t('inProgress'),
              count: provider.inProgressItems.length,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProjectListScreen(filter: ProjectStatusFilter.inProgress),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _BigCard(
              label: strings.t('done'),
              count: provider.doneItems.length,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProjectListScreen(filter: ProjectStatusFilter.done),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddProjectScreen()),
              ),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(strings.t('newProject')),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
              icon: const Icon(Icons.settings_outlined),
              label: Text(strings.t('settings')),
            ),
          ],
        ),
      ),
    );
  }
}

class _BigCard extends StatelessWidget {
  const _BigCard({
    required this.label,
    required this.count,
    required this.onTap,
  });

  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              CircleAvatar(
                child: Text('$count'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
