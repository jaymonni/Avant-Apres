import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/photo_project.dart';
import '../providers/app_provider.dart';

class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _beforeNoteController = TextEditingController();
  final _duringNoteController = TextEditingController();
  final _afterNoteController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  XFile? _before;
  XFile? _during;
  XFile? _after;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _beforeNoteController.dispose();
    _duringNoteController.dispose();
    _afterNoteController.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool fromCamera, required String label}) async {
    final image = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 92,
    );
    if (image == null) return;

    setState(() {
      if (label == 'before') _before = image;
      if (label == 'during') _during = image;
      if (label == 'after') _after = image;
    });
  }

  Future<void> _save() async {
    final strings = AppStrings.of(context);
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${strings.t('title')} requis')),
      );
      return;
    }
    if (_before == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo Avant requise')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<AppProvider>();
    final id = DateTime.now().microsecondsSinceEpoch.toString();

    final folder = await provider.projectFolder(id, title);
    final beforePath = await provider.copyXFileToProject(folder, _before!, 'before');

    String duringPath = '';
    if (_during != null) {
      duringPath = await provider.copyXFileToProject(folder, _during!, 'during');
    }

    String afterPath = '';
    if (_after != null) {
      afterPath = await provider.copyXFileToProject(folder, _after!, 'after');
    }

    final project = PhotoProject(
      id: id,
      title: title,
      createdAt: DateTime.now(),
      status: afterPath.trim().isNotEmpty ? ProjectStatus.done : ProjectStatus.inProgress,
      isFavorite: false,
      beforePath: beforePath,
      afterPath: afterPath,
      duringPath: duringPath.trim().isEmpty ? null : duringPath,
      beforeNote: _beforeNoteController.text.trim(),
      duringNote: _duringNoteController.text.trim(),
      afterNote: _afterNoteController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    await provider.addProject(project);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.t('newProject'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(labelText: strings.t('title')),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(labelText: strings.t('description')),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          _section(
            title: strings.t('before'),
            requiredMark: true,
            image: _before,
            noteController: _beforeNoteController,
            onCamera: () => _pick(fromCamera: true, label: 'before'),
            onGallery: () => _pick(fromCamera: false, label: 'before'),
          ),
          _section(
            title: strings.t('during'),
            image: _during,
            noteController: _duringNoteController,
            onCamera: () => _pick(fromCamera: true, label: 'during'),
            onGallery: () => _pick(fromCamera: false, label: 'during'),
          ),
          _section(
            title: strings.t('after'),
            image: _after,
            noteController: _afterNoteController,
            onCamera: () => _pick(fromCamera: true, label: 'after'),
            onGallery: () => _pick(fromCamera: false, label: 'after'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            child: Text(strings.t('save')),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required XFile? image,
    required TextEditingController noteController,
    required VoidCallback onCamera,
    required VoidCallback onGallery,
    bool requiredMark = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              requiredMark ? '$title *' : title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onCamera,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Camera'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galerie'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              width: double.infinity,
              child: image == null
                  ? const _MissingPhotoPlaceholder()
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(image.path),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const _BrokenPhotoPlaceholder(),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Note'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingPhotoPlaceholder extends StatelessWidget {
  const _MissingPhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey),
      ),
      child: const Center(child: Text('Aucune image')),
    );
  }
}

class _BrokenPhotoPlaceholder extends StatelessWidget {
  const _BrokenPhotoPlaceholder();

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
