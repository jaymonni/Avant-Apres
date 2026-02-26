import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/photo_project.dart';
import '../providers/app_provider.dart';

class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _beforeNoteController = TextEditingController();
  final _duringNoteController = TextEditingController();
  final _afterNoteController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  XFile? _beforeXFile;
  XFile? _duringXFile;
  XFile? _afterXFile;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _beforeNoteController.dispose();
    _duringNoteController.dispose();
    _afterNoteController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto({required bool fromCamera, required String label}) async {
    final source = fromCamera ? ImageSource.camera : ImageSource.gallery;
    final file = await _picker.pickImage(source: source, imageQuality: 92);
    if (file == null || !mounted) return;

    setState(() {
      switch (label) {
        case 'before':
          _beforeXFile = file;
          break;
        case 'during':
          _duringXFile = file;
          break;
        case 'after':
          _afterXFile = file;
          break;
      }
    });
  }

  Future<void> _saveProject() async {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid || _beforeXFile == null) {
      if (_beforeXFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La photo Avant est obligatoire.')),
        );
      }
      return;
    }

    setState(() => _saving = true);

    final now = DateTime.now();
    final id = now.microsecondsSinceEpoch.toString();
    final title = _titleController.text.trim();
    final folder = await LocalProjectFiles.projectFolder(id, title);

    final beforePath = await LocalProjectFiles.copyXFileToProject(_beforeXFile!, folder, 'before');

    String duringPath = '';
    if (_duringXFile != null) {
      duringPath = await LocalProjectFiles.copyXFileToProject(_duringXFile!, folder, 'during');
    }

    String afterPath = '';
    if (_afterXFile != null) {
      afterPath = await LocalProjectFiles.copyXFileToProject(_afterXFile!, folder, 'after');
    }

    final project = PhotoProject(
      id: id,
      title: title,
      createdAt: now,
      status: afterPath.trim().isNotEmpty ? ProjectStatus.done : ProjectStatus.inProgress,
      isFavorite: false,
      beforePath: beforePath,
      afterPath: afterPath,
      duringPath: duringPath,
      beforeNote: _beforeNoteController.text.trim(),
      duringNote: _duringNoteController.text.trim(),
      afterNote: _afterNoteController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    await context.read<AppProvider>().addProject(project);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau projet')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Titre *'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le titre est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description projet (optionnelle)'),
            ),
            const SizedBox(height: 16),
            _photoSection(
              title: 'Avant (obligatoire)',
              noteController: _beforeNoteController,
              xfile: _beforeXFile,
              onCamera: () => _pickPhoto(fromCamera: true, label: 'before'),
              onGallery: () => _pickPhoto(fromCamera: false, label: 'before'),
            ),
            const SizedBox(height: 14),
            _photoSection(
              title: 'Pendant (optionnel)',
              noteController: _duringNoteController,
              xfile: _duringXFile,
              onCamera: () => _pickPhoto(fromCamera: true, label: 'during'),
              onGallery: () => _pickPhoto(fromCamera: false, label: 'during'),
            ),
            const SizedBox(height: 14),
            _photoSection(
              title: 'Après (optionnel)',
              noteController: _afterNoteController,
              xfile: _afterXFile,
              onCamera: () => _pickPhoto(fromCamera: true, label: 'after'),
              onGallery: () => _pickPhoto(fromCamera: false, label: 'after'),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _saving ? null : _saveProject,
              icon: const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Enregistrement...' : 'Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoSection({
    required String title,
    required TextEditingController noteController,
    required XFile? xfile,
    required VoidCallback onCamera,
    required VoidCallback onGallery,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
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
            const SizedBox(height: 10),
            if (xfile != null)
              SizedBox(
                height: 150,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(xfile.path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return const _BrokenImagePlaceholder();
                    },
                  ),
                ),
              )
            else
              const _BrokenImagePlaceholder(text: 'Aucune photo sélectionnée'),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Note sous la photo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrokenImagePlaceholder extends StatelessWidget {
  const _BrokenImagePlaceholder({this.text = 'broken image'});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey),
        color: Colors.grey.withValues(alpha: 0.12),
      ),
      alignment: Alignment.center,
      child: Text(text),
    );
  }
}
