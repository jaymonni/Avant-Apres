import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/photo_project.dart';
import '../providers/app_provider.dart';

class PhotoCard extends StatelessWidget {
  const PhotoCard({
    super.key,
    required this.project,
    required this.onTap,
    required this.onDelete,
  });

  final PhotoProject project;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _openActions(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: project.status == ProjectStatus.done
                          ? Colors.green
                          : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      project.status == ProjectStatus.done
                          ? strings.t('done')
                          : strings.t('inProgress'),
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => context.read<AppProvider>().toggleFavorite(project.id),
                    icon: Icon(
                      project.isFavorite ? Icons.star : Icons.star_outline,
                      color: project.isFavorite ? Colors.amber : null,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(project.beforePath),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const _BrokenPlaceholder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: project.hasAfter
                            ? Image.file(
                                File(project.afterPath),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const _BrokenPlaceholder(),
                              )
                            : Container(
                                color: Colors.grey.shade200,
                                child: Center(
                                  child: Text(strings.t('missingImage')),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                project.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openActions(BuildContext context) async {
    final strings = AppStrings.of(context);
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: Text(strings.t('open')),
              onTap: () {
                Navigator.of(ctx).pop();
                onTap();
              },
            ),
            ListTile(
              leading: Icon(project.isFavorite ? Icons.star_outline : Icons.star),
              title: Text(
                project.isFavorite ? strings.t('unfavorite') : strings.t('favorite'),
              ),
              onTap: () async {
                Navigator.of(ctx).pop();
                await context.read<AppProvider>().toggleFavorite(project.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(strings.t('delete')),
              onTap: () {
                Navigator.of(ctx).pop();
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BrokenPlaceholder extends StatelessWidget {
  const _BrokenPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade300,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined),
            Text('broken image'),
          ],
        ),
      ),
    );
  }
}
