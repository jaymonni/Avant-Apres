import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/photo_project.dart';
import '../providers/app_provider.dart';

class PhotoCard extends StatelessWidget {
  const PhotoCard({
    super.key,
    required this.project,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onDelete,
  });

  final PhotoProject project;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDelete;

  void _openActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.open_in_new_rounded),
                title: Text(AppStrings.open),
                onTap: () {
                  Navigator.of(context).pop();
                  onTap();
                },
              ),
              ListTile(
                leading: Icon(
                  project.isFavorite
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                ),
                title: Text(
                  project.isFavorite
                      ? AppStrings.removeFavorite
                      : AppStrings.favorites,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onToggleFavorite();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: Text(AppStrings.delete),
                onTap: () {
                  Navigator.of(context).pop();
                  onDelete();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _imageOrPlaceholder(
    BuildContext context,
    String path, {
    required String placeholderText,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final exists = LocalFiles.fileExists(path);

    if (!exists) {
      return Container(
        color: colorScheme.onSurface.withValues(alpha: 0.05),
        child: Center(
          child: Text(
            placeholderText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ),
      );
    }

    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: colorScheme.onSurface.withValues(alpha: 0.05),
          child: Center(
            child: Text(
              AppStrings.brokenImage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _cornerBadge(
    BuildContext context, {
    required String text,
    Alignment alignment = Alignment.topLeft,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: colorScheme.onPrimary.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  String _intermediateChipLabel(BuildContext context) {
    final count = project.duringPhotos.length;
    final locale = Localizations.localeOf(context);

    if (locale.languageCode == 'fr') {
      return count == 1 ? '+1 intermédiaire' : '+$count intermédiaires';
    }
    return count == 1 ? '+1 intermediate' : '+$count intermediate';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusText =
        project.status == ProjectStatus.done ? 'DONE' : 'IN PROGRESS';

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _openActions(context),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _imageOrPlaceholder(
                              context,
                              project.beforePath,
                              placeholderText: AppStrings.brokenImage,
                            ),
                            _cornerBadge(
                              context,
                              text: 'AVANT',
                              alignment: Alignment.topLeft,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _imageOrPlaceholder(
                              context,
                              project.afterPath,
                              placeholderText: AppStrings.noPhoto,
                            ),
                            _cornerBadge(
                              context,
                              text: 'APRÈS',
                              alignment: Alignment.topLeft,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                  color: colorScheme.onSurface.withValues(alpha: 0.03),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (project.duringPhotos.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: colorScheme.primary.withValues(alpha: 0.10),
                          ),
                          child: Text(
                            _intermediateChipLabel(context),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              left: 10,
              top: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: project.status == ProjectStatus.done
                      ? Colors.green.withValues(alpha: 0.90)
                      : colorScheme.primary.withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: GestureDetector(
                onTap: onToggleFavorite,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.28),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    project.isFavorite
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}