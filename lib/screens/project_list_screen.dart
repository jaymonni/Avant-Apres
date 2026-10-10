import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/photo_project.dart';
import '../providers/app_provider.dart';
import 'detail_screen.dart';

enum ProjectSortType {
  newestFirst,
  oldestFirst,
  alphabeticalAZ,
  alphabeticalZA,
}

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({
    super.key,
    required this.filter,
  });

  final ProjectStatus filter;

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  ProjectSortType _sortType = ProjectSortType.newestFirst;

  String _tr({
    required String fr,
    required String en,
    required String es,
    required String pt,
  }) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'fr':
        return fr;
      case 'es':
        return es;
      case 'pt':
        return pt;
      default:
        return en;
    }
  }

  Future<void> _confirmDelete(BuildContext context, PhotoProject project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppStrings.deleteProjectTitle),
          content: Text(AppStrings.deleteProjectMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(AppStrings.delete),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await context.read<AppProvider>().deleteProject(project.id);
    }
  }

  void _openProject(PhotoProject project) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailScreen(projectId: project.id),
      ),
    );
  }

  int _compareBySortType(PhotoProject a, PhotoProject b) {
    switch (_sortType) {
      case ProjectSortType.newestFirst:
        return b.createdAt.compareTo(a.createdAt);
      case ProjectSortType.oldestFirst:
        return a.createdAt.compareTo(b.createdAt);
      case ProjectSortType.alphabeticalAZ:
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      case ProjectSortType.alphabeticalZA:
        return b.title.toLowerCase().compareTo(a.title.toLowerCase());
    }
  }

  List<PhotoProject> _sortedItems(List<PhotoProject> items) {
    final sorted = List<PhotoProject>.from(items);

    sorted.sort((a, b) {
      if (a.isFavorite != b.isFavorite) {
        return a.isFavorite ? -1 : 1;
      }
      return _compareBySortType(a, b);
    });

    return sorted;
  }

  String _sortLabel(BuildContext context) {
    switch (_sortType) {
      case ProjectSortType.newestFirst:
        return _tr(
          fr: 'Plus récents',
          en: 'Newest',
          es: 'Más recientes',
          pt: 'Mais recentes',
        );
      case ProjectSortType.oldestFirst:
        return _tr(
          fr: 'Plus anciens',
          en: 'Oldest',
          es: 'Más antiguos',
          pt: 'Mais antigos',
        );
      case ProjectSortType.alphabeticalAZ:
        return 'A → Z';
      case ProjectSortType.alphabeticalZA:
        return 'Z → A';
    }
  }

  String _sortMenuLabel(BuildContext context, ProjectSortType type) {
    switch (type) {
      case ProjectSortType.newestFirst:
        return _tr(
          fr: 'Date : plus récents',
          en: 'Date: newest first',
          es: 'Fecha: más recientes',
          pt: 'Data: mais recentes',
        );
      case ProjectSortType.oldestFirst:
        return _tr(
          fr: 'Date : plus anciens',
          en: 'Date: oldest first',
          es: 'Fecha: más antiguos',
          pt: 'Data: mais antigos',
        );
      case ProjectSortType.alphabeticalAZ:
        return _tr(
          fr: 'Alphabétique : A à Z',
          en: 'Alphabetical: A to Z',
          es: 'Alfabético: A a Z',
          pt: 'Alfabético: A a Z',
        );
      case ProjectSortType.alphabeticalZA:
        return _tr(
          fr: 'Alphabétique : Z à A',
          en: 'Alphabetical: Z to A',
          es: 'Alfabético: Z a A',
          pt: 'Alfabético: Z a A',
        );
    }
  }

  String _intermediateLabel(BuildContext context, int count) {
    if (count <= 0) return '';

    switch (Localizations.localeOf(context).languageCode) {
      case 'fr':
        return count == 1
            ? '1 photo intermédiaire'
            : '$count photos intermédiaires';
      case 'es':
        return count == 1
            ? '1 foto intermedia'
            : '$count fotos intermedias';
      case 'pt':
        return count == 1
            ? '1 foto intermediária'
            : '$count fotos intermediárias';
      default:
        return count == 1
            ? '1 intermediate photo'
            : '$count intermediate photos';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final rawItems = provider.filtered(widget.filter);
    final items = _sortedItems(rawItems);

    final title = widget.filter == ProjectStatus.inProgress
        ? AppStrings.inProgress
        : AppStrings.doneProjects;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          PopupMenuButton<ProjectSortType>(
            tooltip: AppStrings.sort,
            initialValue: _sortType,
            onSelected: (value) {
              setState(() {
                _sortType = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: ProjectSortType.newestFirst,
                child: Text(
                  _sortMenuLabel(context, ProjectSortType.newestFirst),
                ),
              ),
              PopupMenuItem(
                value: ProjectSortType.oldestFirst,
                child: Text(
                  _sortMenuLabel(context, ProjectSortType.oldestFirst),
                ),
              ),
              PopupMenuItem(
                value: ProjectSortType.alphabeticalAZ,
                child: Text(
                  _sortMenuLabel(context, ProjectSortType.alphabeticalAZ),
                ),
              ),
              PopupMenuItem(
                value: ProjectSortType.alphabeticalZA,
                child: Text(
                  _sortMenuLabel(context, ProjectSortType.alphabeticalZA),
                ),
              ),
            ],
            icon: const Icon(Icons.sort_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : colorScheme.primary.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(
                    _sortLabel(context),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      AppStrings.noProjects,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  )
                : ListView.builder(
                    key: PageStorageKey<String>(
                      'projects_list_${widget.filter.name}',
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final project = items[index];
                      final intermediateCount = project.duringPhotos.length;

                      return KeyedSubtree(
                        key: ValueKey(project.id),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : colorScheme.primary.withValues(alpha: 0.08),
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () => _openProject(project),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: SizedBox(
                                      width: 64,
                                      height: 64,
                                      child: Image.file(
                                        File(project.beforePath),
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.06),
                                            child: Icon(
                                              Icons.broken_image_rounded,
                                              color: colorScheme.onSurface
                                                  .withValues(alpha: 0.70),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          project.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          LocalFiles.formatDate(
                                            project.createdAt,
                                          ),
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.66),
                                          ),
                                        ),
                                        if (intermediateCount > 0) ...[
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              color: isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.06,
                                                    )
                                                  : colorScheme.primary
                                                      .withValues(alpha: 0.08),
                                            ),
                                            child: Text(
                                              _intermediateLabel(
                                                context,
                                                intermediateCount,
                                              ),
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: isDark
                                                    ? Colors.white
                                                    : colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      IconButton(
                                        tooltip: project.isFavorite
                                            ? AppStrings.removeFavorite
                                            : AppStrings.favorites,
                                        onPressed: () {
                                          context
                                              .read<AppProvider>()
                                              .toggleFavorite(project.id);
                                        },
                                        icon: Icon(
                                          project.isFavorite
                                              ? Icons.star_rounded
                                              : Icons.star_border_rounded,
                                          color: project.isFavorite
                                              ? const Color(0xFFF59E0B)
                                              : colorScheme.onSurface,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: AppStrings.delete,
                                        onPressed: () =>
                                            _confirmDelete(context, project),
                                        icon: Icon(
                                          Icons.delete_outline_rounded,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}