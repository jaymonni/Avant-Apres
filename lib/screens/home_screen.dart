import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/photo_project.dart';
import '../providers/app_provider.dart';
import '../theme/theme_controller.dart';
import 'add_project_screen.dart';
import 'project_list_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final palette = context.watch<ThemeController>().palette;

    final inProgressCount = appProvider.byStatus(ProjectStatus.inProgress).length;
    final doneCount = appProvider.byStatus(ProjectStatus.done).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Avant / Après',
          style: GoogleFonts.pacifico(fontSize: 28),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'Réglages',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AddProjectScreen()),
          );
        },
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Nouveau'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [palette.gradA.withValues(alpha: 0.25), palette.gradB.withValues(alpha: 0.18)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _HomeBigCard(
                title: 'Projets en cours',
                subtitle: '$inProgressCount projet(s)',
                icon: Icons.timelapse,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProjectListScreen(filter: ProjectStatus.inProgress),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _HomeBigCard(
                title: 'Mes projets',
                subtitle: '$doneCount projet(s)',
                icon: Icons.check_circle_outline,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProjectListScreen(filter: ProjectStatus.done),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              Text(
                'Astuce : appui long sur une carte projet pour les actions rapides.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeBigCard extends StatelessWidget {
  const _HomeBigCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeController>().palette;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [palette.gradA, palette.gradB],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Icon(icon, size: 44, color: Colors.white),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
