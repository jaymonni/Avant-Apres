import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/photo_project.dart';
import '../providers/app_provider.dart';

class PhotoCard extends StatelessWidget {
  const PhotoCard({
    super.key,
    required this.project,
    required this.onTap,
  });

  final PhotoProject project;
  final VoidCallback onTap;

  bool _exists(String path) => path.trim().isNotEmpty && File(path).existsSync();

  @override
  Widget build(BuildContext context) {
    final beforeExists = _exists(project.beforePath);
    final afterExists = _exists(project.afterPath);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showActions(context),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _imageCell(
                        filePath: beforeExists ? project.beforePath : '',
                        label: 'Avant',
                        isAfterSlot: false,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _imageCell(
                        filePath: afterExists ? project.afterPath : '',
                        label: 'Après',
                        isAfterSlot: true,
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
              const SizedBox(height: 2),
              Text(DateFormat('dd/MM/yyyy').format(project.createdAt)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _badge(
                    text: project.status == ProjectStatus.done ? 'Terminé' : 'En cours',
                    color: project.status == ProjectStatus.done ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  if (project.isFavorite) _badge(text: 'Favori', color: Colors.pink),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageCell({
    required String filePath,
    required String label,
    required bool isAfterSlot,
  }) {
    final hasFile = filePath.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasFile)
            Image.file(
              File(filePath),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildMissingVisual(isAfterSlot: isAfterSlot),
            )
          else
            _buildMissingVisual(isAfterSlot: isAfterSlot),
          Positioned(
            left: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.48),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingVisual({required bool isAfterSlot}) {
    if (isAfterSlot) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF5E6), Color(0xFFFFE5BF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_photo_alternate_outlined, color: Color(0xFFB36B00)),
              SizedBox(height: 4),
              Text(
                'À compléter',
                style: TextStyle(
                  color: Color(0xFFB36B00),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.blueGrey.withValues(alpha: 0.25),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, color: Colors.black54),
            SizedBox(height: 4),
            Text('Image manquante'),
          ],
        ),
      ),
    );
  }

  Widget _badge({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Future<void> _showActions(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: const Text('Ouvrir'),
                onTap: () {
                  Navigator.pop(context);
                  onTap();
                },
              ),
              ListTile(
                leading: Icon(project.isFavorite ? Icons.favorite : Icons.favorite_border),
                title: Text(project.isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris'),
                onTap: () async {
                  Navigator.pop(context);
                  await context.read<AppProvider>().toggleFavorite(project.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Supprimer'),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Suppression'),
                      content: const Text('Voulez-vous supprimer ce projet ?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Annuler'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Supprimer'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    await context.read<AppProvider>().deleteProject(project.id);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
