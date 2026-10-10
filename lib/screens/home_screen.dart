import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/photo_project.dart';
import '../providers/app_provider.dart';
import '../widgets/ad_banner_widget.dart';
import 'add_project_screen.dart';
import 'project_list_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openNewProject(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddProjectScreen()),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _openProjects(BuildContext context, ProjectStatus status) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectListScreen(filter: status),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final inProgressCount = provider.filtered(ProjectStatus.inProgress).length;
    final doneCount = provider.filtered(ProjectStatus.done).length;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          AppStrings.appTitle,
          style: GoogleFonts.pacifico(
            fontSize: 30,
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          IconButton(
            tooltip: AppStrings.settings,
            onPressed: () => _openSettings(context),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    Theme.of(context).scaffoldBackgroundColor,
                    colorScheme.primary.withValues(alpha: 0.05),
                  ]
                : [
                    Theme.of(context).scaffoldBackgroundColor,
                    colorScheme.primary.withValues(alpha: 0.04),
                  ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              _MinimalHeroCard(isDark: isDark),
              const SizedBox(height: 22),
              _ProjectCard(
                title: AppStrings.inProgress,
                icon: Icons.hourglass_top_rounded,
                statusColor: const Color(0xFFF59E0B),
                count: inProgressCount,
                isDark: isDark,
                onTap: () => _openProjects(context, ProjectStatus.inProgress),
              ),
              const SizedBox(height: 14),
              _ProjectCard(
                title: AppStrings.doneProjects,
                icon: Icons.verified_rounded,
                statusColor: const Color(0xFF10B981),
                count: doneCount,
                isDark: isDark,
                onTap: () => _openProjects(context, ProjectStatus.done),
              ),
              const SizedBox(height: 22),
              _PrimaryActionButton(
                onPressed: () => _openNewProject(context),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AdBannerWidget(),
    );
  }
}

class _MinimalHeroCard extends StatelessWidget {
  const _MinimalHeroCard({
    required this.isDark,
  });

  final bool isDark;

  String _heroTitle(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'fr':
        return 'Capturez chaque transformation';
      case 'es':
        return 'Captura cada transformación';
      case 'pt':
        return 'Capture cada transformação';
      default:
        return 'Capture every transformation';
    }
  }

  String _heroSubtitle(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'fr':
        return 'en toute simplicité';
      case 'es':
        return 'con facilidad';
      case 'pt':
        return 'com facilidade';
      default:
        return 'with ease';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  colorScheme.primary.withValues(alpha: 0.14),
                  colorScheme.secondary.withValues(alpha: 0.08),
                ]
              : [
                  colorScheme.primary.withValues(alpha: 0.12),
                  colorScheme.secondary.withValues(alpha: 0.07),
                ],
        ),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.white.withValues(alpha: 0.75),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 30,
              color: isDark ? Colors.white : colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _heroTitle(context),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _heroSubtitle(context),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.76)
                  : colorScheme.onSurface.withValues(alpha: 0.70),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.title,
    required this.icon,
    required this.statusColor,
    required this.count,
    required this.isDark,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color statusColor;
  final int count;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.92),
          border: Border.all(
            width: 1.2,
            color: isDark
                ? colorScheme.primary.withValues(alpha: 0.22)
                : colorScheme.primary.withValues(alpha: 0.14),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: statusColor.withValues(alpha: isDark ? 0.24 : 0.14),
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: isDark ? Colors.white : statusColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: isDark ? 0.20 : 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.78)
                    : colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  String _buttonLabel(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'fr':
        return 'Nouveau projet';
      case 'es':
        return 'Nuevo proyecto';
      case 'pt':
        return 'Novo projeto';
      default:
        return 'New project';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.20 : 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        height: 54,
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            _buttonLabel(context),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ),
      ),
    );
  }
}