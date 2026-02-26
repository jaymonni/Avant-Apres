import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../models/photo_project.dart';
import '../providers/app_provider.dart';
import '../widgets/before_after_slider.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.projectId});

  final String projectId;

  bool _exists(String path) => path.trim().isNotEmpty && File(path).existsSync();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final project = provider.byId(projectId);

    if (project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Projet')),
        body: const Center(child: Text('Projet introuvable')),
      );
    }

    final beforeExists = _exists(project.beforePath);
    final duringExists = _exists(project.duringPath ?? '');
    final afterExists = _exists(project.afterPath);

    return Scaffold(
      appBar: AppBar(title: Text(project.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(project.title, style: Theme.of(context).textTheme.headlineSmall),
          Text(DateFormat('dd/MM/yyyy HH:mm').format(project.createdAt)),
          if (project.description.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(project.description),
          ],
          const SizedBox(height: 16),
          if (beforeExists && afterExists)
            BeforeAfterSlider(
              beforeImagePath: project.beforePath,
              afterImagePath: project.afterPath,
              sliderHeight: 280,
              showFrame: true,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _singleImageCard('Avant', project.beforePath),
                if (project.beforeNote.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('Note avant : ${project.beforeNote}'),
                  ),
                if (project.hasDuring) ...[
                  _singleImageCard('Pendant', project.duringPath ?? ''),
                  if (project.duringNote.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('Note pendant : ${project.duringNote}'),
                    ),
                ] else if (duringExists) ...[
                  _singleImageCard('Pendant', project.duringPath ?? ''),
                ],
                _singleImageCard('Après', project.afterPath),
                if (project.afterNote.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Note après : ${project.afterNote}'),
                  ),
              ],
            ),
          if (project.status == ProjectStatus.inProgress) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _showCompleteBottomSheet(context, project),
              icon: const Icon(Icons.done_all),
              label: const Text('Compléter'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _singleImageCard(String label, String path) {
    final exists = _exists(path);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: exists
                    ? Image.file(
                        File(path),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const _BrokenImage(),
                      )
                    : const _BrokenImage(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCompleteBottomSheet(BuildContext context, PhotoProject project) async {
    final duringNoteController = TextEditingController(text: project.duringNote);
    final afterNoteController = TextEditingController(text: project.afterNote);
    final picker = ImagePicker();
    XFile? duringXFile;
    XFile? afterXFile;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Compléter le projet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _pickRow(
                      title: 'Photo Après',
                      onCamera: () async {
                        afterXFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 92);
                        setState(() {});
                      },
                      onGallery: () async {
                        afterXFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 92);
                        setState(() {});
                      },
                      selectedPath: afterXFile?.path,
                    ),
                    const SizedBox(height: 10),
                    _pickRow(
                      title: 'Photo Pendant',
                      onCamera: () async {
                        duringXFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 92);
                        setState(() {});
                      },
                      onGallery: () async {
                        duringXFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 92);
                        setState(() {});
                      },
                      selectedPath: duringXFile?.path,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: duringNoteController,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Note Pendant'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: afterNoteController,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Note Après'),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () async {
                        final beforeFolder = Directory(p.dirname(project.beforePath));
                        String? duringPath;
                        String? afterPath;

                        if (duringXFile != null) {
                          duringPath = await LocalProjectFiles.copyXFileToProject(duringXFile!, beforeFolder, 'during');
                        }
                        if (afterXFile != null) {
                          afterPath = await LocalProjectFiles.copyXFileToProject(afterXFile!, beforeFolder, 'after');
                        }

                        await context.read<AppProvider>().updateProjectNotesAndPhotos(
                              project.id,
                              afterPath: afterPath,
                              duringPath: duringPath,
                              afterNote: afterNoteController.text.trim(),
                              duringNote: duringNoteController.text.trim(),
                            );

                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Enregistrer'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    duringNoteController.dispose();
    afterNoteController.dispose();
  }

  Widget _pickRow({
    required String title,
    required VoidCallback onCamera,
    required VoidCallback onGallery,
    String? selectedPath,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onCamera,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Caméra'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galerie'),
                ),
              ],
            ),
            if (selectedPath != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(selectedPath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _BrokenImage(),
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

class _BrokenImage extends StatelessWidget {
  const _BrokenImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: const Text('broken image'),
    );
  }
}
