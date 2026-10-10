import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/photo_project.dart';
import '../providers/app_provider.dart';
import 'crop_image_screen.dart';

class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _DraftDuringPhoto {
  _DraftDuringPhoto({
    required this.noteController,
  });

  XFile? xfile;
  DateTime? date;
  final TextEditingController noteController;

  void dispose() {
    noteController.dispose();
  }
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  static const double _projectFrameAspectRatio = 16 / 9;

  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _beforeNoteController = TextEditingController();
  final _afterNoteController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  XFile? _beforeXFile;
  XFile? _afterXFile;
  DateTime? _afterDate;

  final List<_DraftDuringPhoto> _duringDrafts = [];

  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _beforeNoteController.dispose();
    _afterNoteController.dispose();
    for (final item in _duringDrafts) {
      item.dispose();
    }
    super.dispose();
  }

  String _tr(
    String fr,
    String en,
    String es,
    String pt,
  ) {
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

  String _stepTitle(int index) {
    return _tr(
      'Étape ${index + 1} (facultatif)',
      'Step ${index + 1} (optional)',
      'Paso ${index + 1} (opcional)',
      'Etapa ${index + 1} (opcional)',
    );
  }

  String _stepHelper() {
    return _tr(
      'Ajoutez une photo pour montrer la progression du projet.',
      'Add a photo to show the project progress.',
      'Añade una foto para mostrar el progreso del proyecto.',
      'Adicione uma foto para mostrar o progresso do projeto.',
    );
  }

  Future<XFile?> _cropPickedFile(XFile picked) async {
    final croppedPath = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => CropImageScreen(
          sourcePath: picked.path,
          title: _tr(
            'Rogner la photo',
            'Crop image',
            'Recortar imagen',
            'Recortar imagem',
          ),
          aspectRatio: _projectFrameAspectRatio,
        ),
      ),
    );

    if (croppedPath == null || croppedPath.trim().isEmpty) {
      return null;
    }

    return XFile(croppedPath);
  }

  Future<void> _pickImage({
    required String label,
    required ImageSource source,
    int? duringIndex,
  }) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1600,
      maxHeight: 1600,
    );

    if (picked == null) return;
    if (!mounted) return;

    final cropped = await _cropPickedFile(picked);
    if (cropped == null) return;
    if (!mounted) return;

    setState(() {
      if (label == 'before') {
        _beforeXFile = cropped;
      } else if (label == 'after') {
        _afterXFile = cropped;
      } else if (label == 'during' && duringIndex != null) {
        _duringDrafts[duringIndex].xfile = cropped;
      }
    });
  }

  Future<void> _pickDate({
    required void Function(DateTime) onSelected,
    DateTime? initial,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      onSelected(picked);
    }
  }

  String _dateText(DateTime? date) {
    if (date == null) {
      return _tr(
        'Choisir une date',
        'Choose a date',
        'Elegir una fecha',
        'Escolher uma data',
      );
    }
    return LocalFiles.formatDate(date);
  }

  String _duringPhotosLabel() {
    final count = _duringDrafts.where((e) => e.xfile != null).length;
    switch (Localizations.localeOf(context).languageCode) {
      case 'fr':
        return 'Photos intermédiaires ($count)';
      case 'es':
        return 'Fotos intermedias ($count)';
      case 'pt':
        return 'Fotos intermediárias ($count)';
      default:
        return 'Intermediate photos ($count)';
    }
  }

  void _addDuringDraft() {
    _duringDrafts.add(
      _DraftDuringPhoto(
        noteController: TextEditingController(),
      ),
    );
  }

  void _removeDuringDraftAt(int index) {
    _duringDrafts[index].dispose();
    _duringDrafts.removeAt(index);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _saveProject() async {
    if (_isSaving) return;

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_beforeXFile == null) {
      _showSnack(AppStrings.beforeRequired);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final provider = context.read<AppProvider>();
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      final title = _titleController.text.trim();

      final folder = await LocalFiles.projectFolder(id, title);

      final beforePath = await LocalFiles.copyXFileToProject(
        folder,
        _beforeXFile!,
        'before',
      );

      final duringPhotos = <DuringPhoto>[];
      int duringCounter = 1;

      for (final item in _duringDrafts) {
        if (item.xfile == null) continue;

        final path = await LocalFiles.copyXFileToProject(
          folder,
          item.xfile!,
          'during_$duringCounter',
        );

        duringPhotos.add(
          DuringPhoto(
            id: 'during_$duringCounter',
            path: path,
            note: item.noteController.text.trim(),
            date: item.date,
          ),
        );

        duringCounter++;
      }

      String afterPath = '';
      if (_afterXFile != null) {
        afterPath = await LocalFiles.copyXFileToProject(
          folder,
          _afterXFile!,
          'after',
        );
      }

      final project = PhotoProject(
        id: id,
        title: title,
        createdAt: DateTime.now(),
        status: afterPath.trim().isNotEmpty
            ? ProjectStatus.done
            : ProjectStatus.inProgress,
        isFavorite: false,
        beforePath: beforePath,
        afterPath: afterPath,
        beforeNote: _beforeNoteController.text.trim(),
        afterNote: _afterNoteController.text.trim(),
        description: _descriptionController.text.trim(),
        duringPhotos: duringPhotos,
        afterDate: _afterDate,
      );

      await provider.addProject(project);

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      _showSnack(
        _tr(
          'Erreur : $e',
          'Error: $e',
          'Error: $e',
          'Erro: $e',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildPreview(XFile? file) {
    final colorScheme = Theme.of(context).colorScheme;

    if (file == null) {
      return Container(
        color: colorScheme.onSurface.withValues(alpha: 0.05),
        child: Center(
          child: Text(
            AppStrings.preview,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ),
      );
    }

    return Image(
      image: ResizeImage(
        FileImage(File(file.path)),
        width: 1200,
      ),
      fit: BoxFit.cover,
      alignment: Alignment.center,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: colorScheme.onSurface.withValues(alpha: 0.05),
          child: Center(
            child: Text(
              AppStrings.brokenImage,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(
    String label, {
    String? hint,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(
        color: colorScheme.onSurface.withValues(alpha: 0.86),
      ),
      hintStyle: TextStyle(
        color: colorScheme.onSurface.withValues(alpha: 0.50),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.42),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: colorScheme.primary,
          width: 1.6,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildPhotoBlock({
    required String title,
    required XFile? file,
    required VoidCallback onCamera,
    required VoidCallback onGallery,
    required TextEditingController noteController,
    bool requiredField = false,
    DateTime? date,
    VoidCallback? onPickDate,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              requiredField ? '$title *' : title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCamera,
                    icon: const Icon(Icons.photo_camera_rounded),
                    label: Text(AppStrings.camera),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onGallery,
                    icon: const Icon(Icons.photo_library_rounded),
                    label: Text(AppStrings.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AspectRatio(
              aspectRatio: _projectFrameAspectRatio,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildPreview(file),
              ),
            ),
            if (onPickDate != null) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onPickDate,
                icon: const Icon(Icons.calendar_month_rounded),
                label: Text(_dateText(date)),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLines: 2,
              style: TextStyle(
                color: colorScheme.onSurface,
              ),
              decoration: _inputDecoration(AppStrings.note),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDuringPhotosEditor() async {
    if (_duringDrafts.isEmpty) {
      _addDuringDraft();
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          final colorScheme = Theme.of(context).colorScheme;

          Widget buildDuringCard(int index) {
            final item = _duringDrafts[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _stepTitle(index),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _stepHelper(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withValues(alpha: 0.62),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _removeDuringDraftAt(index);
                              if (_duringDrafts.isEmpty) {
                                _addDuringDraft();
                              }
                            });
                            setSheetState(() {});
                          },
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await _pickImage(
                                label: 'during',
                                source: ImageSource.camera,
                                duringIndex: index,
                              );
                              setSheetState(() {});
                            },
                            icon: const Icon(Icons.photo_camera_rounded),
                            label: Text(AppStrings.camera),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await _pickImage(
                                label: 'during',
                                source: ImageSource.gallery,
                                duringIndex: index,
                              );
                              setSheetState(() {});
                            },
                            icon: const Icon(Icons.photo_library_rounded),
                            label: Text(AppStrings.gallery),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    AspectRatio(
                      aspectRatio: _projectFrameAspectRatio,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _buildPreview(item.xfile),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await _pickDate(
                          initial: item.date,
                          onSelected: (value) {
                            setState(() {
                              item.date = value;
                            });
                          },
                        );
                        setSheetState(() {});
                      },
                      icon: const Icon(Icons.calendar_month_rounded),
                      label: Text(_dateText(item.date)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: item.noteController,
                      maxLines: 2,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                      ),
                      decoration: _inputDecoration(AppStrings.note),
                    ),
                  ],
                ),
              ),
            );
          }

          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          final bottomSafe = MediaQuery.of(context).padding.bottom;

          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16 + bottomInset + bottomSafe,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                      Expanded(
                        child: Text(
                          _tr(
                            'Photos intermédiaires',
                            'Intermediate photos',
                            'Fotos intermedias',
                            'Fotos intermediárias',
                          ),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(_duringDrafts.length, buildDuringCard),
                  SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _addDuringDraft();
                            });
                            setSheetState(() {});
                          },
                          icon: const Icon(Icons.add_photo_alternate_rounded),
                          label: Text(
                            _tr(
                              'Ajouter une photo',
                              'Add a photo',
                              'Añadir una foto',
                              'Adicionar uma foto',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.newProject,
          style: TextStyle(
            color: colorScheme.onSurface,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 120 + bottomInset),
          children: [
            TextFormField(
              controller: _titleController,
              style: TextStyle(
                color: colorScheme.onSurface,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppStrings.titleRequired;
                }
                return null;
              },
              decoration: _inputDecoration('${AppStrings.title} *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              style: TextStyle(
                color: colorScheme.onSurface,
              ),
              decoration: _inputDecoration(AppStrings.description),
            ),
            const SizedBox(height: 14),
            _buildPhotoBlock(
              title: AppStrings.before,
              file: _beforeXFile,
              requiredField: true,
              onCamera: () => _pickImage(
                label: 'before',
                source: ImageSource.camera,
              ),
              onGallery: () => _pickImage(
                label: 'before',
                source: ImageSource.gallery,
              ),
              noteController: _beforeNoteController,
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                onTap: _openDuringPhotosEditor,
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(
                  _duringPhotosLabel(),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurface.withValues(alpha: 0.78),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildPhotoBlock(
              title: AppStrings.after,
              file: _afterXFile,
              onCamera: () => _pickImage(
                label: 'after',
                source: ImageSource.camera,
              ),
              onGallery: () => _pickImage(
                label: 'after',
                source: ImageSource.gallery,
              ),
              noteController: _afterNoteController,
              date: _afterDate,
              onPickDate: () => _pickDate(
                initial: _afterDate,
                onSelected: (value) {
                  setState(() {
                    _afterDate = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SizedBox(
            height: 54,
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSaving ? null : _saveProject,
              child: _isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(AppStrings.save),
            ),
          ),
        ),
      ),
    );
  }
}