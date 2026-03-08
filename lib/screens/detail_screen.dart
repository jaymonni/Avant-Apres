import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/photo_project.dart';
import '../providers/app_provider.dart';
import '../widgets/before_after_slider.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final provider = context.watch<AppProvider>();
    final project = provider.byId(projectId);

    if (project == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Projet introuvable')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(project.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(DateFormat('dd/MM/yyyy HH:mm').format(project.createdAt)),
          if (project.description.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(project.description),
          ],
          const SizedBox(height: 16),
          if (project.hasAfter)
            BeforeAfterSlider(
              beforeImagePath: project.beforePath,
              afterImagePath: project.afterPath,
              sliderHeight: 280,
              showFrame: true,
              frameColor: Theme.of(context).colorScheme.primary,
            )
          else
            _imageSection(strings.t('before'), project.beforePath, project.beforeNote),
          if (project.hasDuring) ...[
            const SizedBox(height: 12),
            _imageSection(strings.t('during'), project.duringPath ?? '', project.duringNote),
          ],
          if (project.hasAfter) ...[
            const SizedBox(height: 12),
            _imageSection(strings.t('after'), project.afterPath, project.afterNote),
          ],
          if (!project.hasAfter && !project.hasDuring) ...[
            const SizedBox(height: 12),
            _placeholder('Pas encore de photo complémentaire'),
          ],
        ],
      ),
      floatingActionButton: project.status == ProjectStatus.inProgress
          ? FloatingActionButton.extended(
              onPressed: () => _showCompleteSheet(context, project),
              icon: const Icon(Icons.check),
              label: Text(strings.t('complete')),
            )
          : null,
    );
  }

  Widget _imageSection(String title, String path, String note) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 220,
            width: double.infinity,
            child: path.trim().isEmpty
                ? _placeholder('Image absente')
                : Image.file(
                    File(path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder('broken image'),
                  ),
          ),
        ),
        if (note.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(note),
        ],
      ],
    );
  }

  Widget _placeholder(String text) {
    return Container(
      color: Colors.grey.shade300,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image_outlined),
            Text(text),
          ],
        ),
      ),
    );
  }

  Future<void> _showCompleteSheet(BuildContext context, PhotoProject project) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CompleteProjectSheet(projectId: project.id),
    );
  }
}

class _CompleteProjectSheet extends StatefulWidget {
  const _CompleteProjectSheet({required this.projectId});

  final String projectId;

  @override
  State<_CompleteProjectSheet> createState() => _CompleteProjectSheetState();
}

class _CompleteProjectSheetState extends State<_CompleteProjectSheet> {
  final ImagePicker _picker = ImagePicker();

  XFile? _newAfter;
  XFile? _newDuring;
  bool _saving = false;

  late TextEditingController _duringNoteController;
  late TextEditingController _afterNoteController;

  @override
  void initState() {
    super.initState();
    final project = context.read<AppProvider>().byId(widget.projectId);
    _duringNoteController = TextEditingController(text: project?.duringNote ?? '');
    _afterNoteController = TextEditingController(text: project?.afterNote ?? '');
  }

  @override
  void dispose() {
    _duringNoteController.dispose();
    _afterNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final project = context.watch<AppProvider>().byId(widget.projectId);
    if (project == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.t('complete'), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _pickerRow(
              title: strings.t('after'),
              onCamera: () => _pick('after', true),
              onGallery: () => _pick('after', false),
              currentPath: _newAfter?.path ?? project.afterPath,
            ),
            TextField(
              controller: _afterNoteController,
              decoration: InputDecoration(labelText: '${strings.t('after')} note'),
            ),
            const SizedBox(height: 12),
            _pickerRow(
              title: strings.t('during'),
              onCamera: () => _pick('during', true),
              onGallery: () => _pick('during', false),
              currentPath: _newDuring?.path ?? (project.duringPath ?? ''),
            ),
            TextField(
              controller: _duringNoteController,
              decoration: InputDecoration(labelText: '${strings.t('during')} note'),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _saving ? null : () => _save(context, project),
              child: Text(strings.t('save')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickerRow({
    required String title,
    required VoidCallback onCamera,
    required VoidCallback onGallery,
    required String currentPath,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: [
            TextButton.icon(
              onPressed: onCamera,
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Camera'),
            ),
            TextButton.icon(
              onPressed: onGallery,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Galerie'),
            ),
          ],
        ),
        SizedBox(
          height: 120,
          width: double.infinity,
          child: currentPath.trim().isEmpty
              ? Container(
                  color: Colors.grey.shade300,
                  child: const Center(child: Text('Image absente')),
                )
              : Image.file(
                  File(currentPath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade300,
                    child: const Center(child: Text('broken image')),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _pick(String label, bool fromCamera) async {
    final result = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 92,
    );
    if (result == null) return;

    setState(() {
      if (label == 'after') _newAfter = result;
      if (label == 'during') _newDuring = result;
    });
  }

  Future<void> _save(BuildContext context, PhotoProject project) async {
    setState(() => _saving = true);
    final provider = context.read<AppProvider>();
    final folder = File(project.beforePath).parent;

    String? afterPath;
    String? duringPath;

    if (_newAfter != null) {
      afterPath = await provider.copyXFileToProject(folder, _newAfter!, 'after');
    }
    if (_newDuring != null) {
      duringPath = await provider.copyXFileToProject(folder, _newDuring!, 'during');
    }

    await provider.updateProjectNotesAndPhotos(
      project.id,
      afterPath: afterPath,
      duringPath: duringPath,
      afterNote: _afterNoteController.text.trim(),
      duringNote: _duringNoteController.text.trim(),
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
