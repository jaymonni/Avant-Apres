import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/photo_project.dart';
import '../providers/app_provider.dart';
import '../services/share_project_service.dart';
import '../widgets/before_after_slider.dart';
import 'crop_image_screen.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({
    super.key,
    required this.projectId,
  });

  final String projectId;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

enum _ComparisonMode {
  slider,
  sideBySide,
}

class _DetailScreenState extends State<DetailScreen> {
  _ComparisonMode _comparisonMode = _ComparisonMode.slider;
  bool _isSharing = false;

  Future<void> _confirmDelete(BuildContext context, String projectId) async {
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

    if (confirmed == true && context.mounted) {
      await context.read<AppProvider>().deleteProject(projectId);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _shareProject(PhotoProject project) async {
    if (_isSharing) return;

    final hasBefore = LocalFiles.fileExists(project.beforePath);
    final hasAfter = LocalFiles.fileExists(project.afterPath);

    if (!hasBefore || !hasAfter || project.status != ProjectStatus.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              context,
              'Le projet doit être terminé avec une photo avant et après.',
              'The project must be completed with before and after photos.',
              'El proyecto debe estar terminado con una foto de antes y después.',
              'O projeto deve estar concluído com uma foto de antes e depois.',
            ),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSharing = true;
    });

    try {
      await ShareProjectService.shareFinishedProject(
        project,
        shareText: _tr(
          context,
          'Transformation "${project.title}" créée avec Avant / Après',
          'Transformation "${project.title}" created with Avant / Après',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              context,
              'Erreur de partage : $e',
              'Share error: $e',
              'Error al compartir: $e',
              'Erro ao compartilhar: $e',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  Future<void> _openEditNotesSheet(PhotoProject project) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _EditProjectNotesSheet(project: project),
    );
  }

  Future<void> _openEditDuringPhotoSheet(
    PhotoProject project,
    DuringPhoto duringPhoto,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _EditDuringPhotoSheet(
        projectId: project.id,
        duringPhoto: duringPhoto,
      ),
    );
  }

  String _tr(
    BuildContext context,
    String fr,
    String en, [
    String? es,
    String? pt,
  ]) {
    final locale = Localizations.localeOf(context);

    switch (locale.languageCode) {
      case 'fr':
        return fr;
      case 'es':
        return es ?? en;
      case 'pt':
        return pt ?? en;
      default:
        return en;
    }
  }

  String _dateLabel(BuildContext context, DateTime? date) {
    if (date == null) {
      return _tr(context, 'Date non renseignée', 'No date set', 'Fecha no indicada', 'Data não informada');
    }
    return LocalFiles.formatDate(date);
  }

  String _duringPhotosLabel(BuildContext context, int count) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'fr') {
      return 'Photos intermédiaires ($count)';
    }
    return 'Intermediate photos ($count)';
  }

  String _comparisonModeLabel(_ComparisonMode mode) {
    switch (mode) {
      case _ComparisonMode.slider:
        return _tr(context, 'Slider', 'Slider', 'Deslizador', 'Controle deslizante');
      case _ComparisonMode.sideBySide:
        return _tr(context, 'Côte à côte', 'Side by side', 'Lado a lado', 'Lado a lado');
    }
  }

  void _openDuringPhotosSheet(BuildContext context, PhotoProject project) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _DuringPhotosSheet(
        project: project,
        onOpenGallery: _openFullscreenGallery,
        onOpenSingle: _openSingleImageViewer,
        onEditDuringPhoto: (duringPhoto) {
          Navigator.of(context).pop();
          _openEditDuringPhotoSheet(context.read<AppProvider>().byId(project.id) ?? project, duringPhoto);
        },
      ),
    );
  }

  void _openFullscreenGallery(
    BuildContext context,
    List<_GalleryImageItem> items, {
    int initialIndex = 0,
  }) {
    if (items.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullscreenGalleryScreen(
          items: items,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  void _openSingleImageViewer(
    BuildContext context, {
    required String title,
    required String path,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SingleImageViewerScreen(
          title: title,
          imagePath: path,
        ),
      ),
    );
  }

  Widget _buildComparisonToggle() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget item(_ComparisonMode mode, IconData icon) {
      final selected = _comparisonMode == mode;

      return Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _comparisonMode = mode;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: selected
                  ? colorScheme.primary.withValues(alpha: isDark ? 0.24 : 0.12)
                  : colorScheme.onSurface.withValues(alpha: isDark ? 0.05 : 0.04),
              border: Border.all(
                color: selected
                    ? colorScheme.primary.withValues(alpha: 0.40)
                    : colorScheme.outline.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.72),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _comparisonModeLabel(mode),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: selected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.82),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        item(_ComparisonMode.slider, Icons.tune_rounded),
        const SizedBox(width: 10),
        item(_ComparisonMode.sideBySide, Icons.view_week_rounded),
      ],
    );
  }

  List<_GalleryImageItem> _beforeAfterGalleryItems(PhotoProject project) {
    return [
      _GalleryImageItem(
        path: project.beforePath,
        title: AppStrings.before,
      ),
      _GalleryImageItem(
        path: project.afterPath,
        title: AppStrings.after,
      ),
    ];
  }

  Widget _buildSideBySide(PhotoProject project) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ImageSection(
            title: AppStrings.before,
            imagePath: project.beforePath,
            note: '',
            allowEmpty: false,
            extraText: null,
            compact: true,
            onTapImage: () {
              _openSingleImageViewer(
                context,
                title: AppStrings.before,
                path: project.beforePath,
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ImageSection(
            title: AppStrings.after,
            imagePath: project.afterPath,
            note: '',
            allowEmpty: false,
            extraText: null,
            compact: true,
            onTapImage: () {
              _openSingleImageViewer(
                context,
                title: AppStrings.after,
                path: project.afterPath,
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final project = provider.byId(widget.projectId);

    if (project == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(AppStrings.missingProject),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final hasBefore = LocalFiles.fileExists(project.beforePath);
    final hasAfter = LocalFiles.fileExists(project.afterPath);
    final canShare =
        project.status == ProjectStatus.done && hasBefore && hasAfter;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          project.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (canShare)
            IconButton(
              onPressed: _isSharing ? null : () => _shareProject(project),
              icon: _isSharing
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share_rounded),
            ),
          IconButton(
            onPressed: () => _openEditNotesSheet(project),
            icon: const Icon(Icons.edit_note_rounded),
            tooltip: _tr(context, 'Modifier les notes', 'Edit notes', 'Editar notas', 'Editar notas'),
          ),
          IconButton(
            onPressed: () => context.read<AppProvider>().toggleFavorite(project.id),
            icon: Icon(
              project.isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
            ),
          ),
          IconButton(
            onPressed: () => _confirmDelete(context, project.id),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
        children: [
          Text(
            LocalFiles.formatDate(project.createdAt),
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: _tr(context, 'Description', 'Description', 'Descripción', 'Descrição'),
            trailing: IconButton(
              onPressed: () => _openEditNotesSheet(project),
              icon: const Icon(Icons.edit_rounded),
              tooltip: _tr(context, 'Modifier', 'Edit', 'Editar', 'Editar'),
            ),
            child: Text(
              project.description.trim().isEmpty
                  ? _tr(context, 'Aucune description', 'No description', 'Sin descripción', 'Sem descrição')
                  : project.description,
              style: TextStyle(
                color: project.description.trim().isEmpty
                    ? colorScheme.onSurface.withValues(alpha: 0.62)
                    : colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: _tr(context, 'Comparaison', 'Comparison', 'Comparación', 'Comparação'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasBefore && hasAfter) ...[
                  _buildComparisonToggle(),
                  const SizedBox(height: 12),
                  if (_comparisonMode == _ComparisonMode.slider) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppStrings.before,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          AppStrings.after,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    BeforeAfterSlider(
                      beforeImagePath: project.beforePath,
                      afterImagePath: project.afterPath,
                      sliderHeight: 280,
                      showFrame: true,
                      frameColor: colorScheme.primary.withValues(alpha: 0.18),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (canShare)
                            FilledButton.tonalIcon(
                              onPressed: _isSharing ? null : () => _shareProject(project),
                              icon: _isSharing
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.share_rounded),
                              label: Text(_tr(context, 'Partager', 'Share', 'Compartir', 'Compartilhar')),
                            ),
                          TextButton.icon(
                            onPressed: () {
                              _openFullscreenGallery(
                                context,
                                _beforeAfterGalleryItems(project),
                                initialIndex: 0,
                              );
                            },
                            icon: const Icon(Icons.open_in_full_rounded),
                            label: Text(_tr(context, 'Voir en grand', 'Open full screen', 'Ver en grande', 'Ver em tela cheia')),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    _buildSideBySide(project),
                    if (canShare) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.tonalIcon(
                          onPressed: _isSharing ? null : () => _shareProject(project),
                          icon: _isSharing
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.share_rounded),
                          label: Text(_tr(context, 'Partager', 'Share', 'Compartir', 'Compartilhar')),
                        ),
                      ),
                    ],
                  ],
                ] else ...[
                  _ImageSection(
                    title: AppStrings.before,
                    imagePath: project.beforePath,
                    note: '',
                    allowEmpty: false,
                    extraText: null,
                    compact: true,
                    onTapImage: () {
                      _openSingleImageViewer(
                        context,
                        title: AppStrings.before,
                        path: project.beforePath,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _ImageSection(
                    title: AppStrings.after,
                    imagePath: project.afterPath,
                    note: '',
                    allowEmpty: true,
                    extraText: null,
                    compact: true,
                    onTapImage: LocalFiles.fileExists(project.afterPath)
                        ? () {
                            _openSingleImageViewer(
                              context,
                              title: AppStrings.after,
                              path: project.afterPath,
                            );
                          }
                        : null,
                  ),
                ],
              ],
            ),
          ),
          if (project.duringPhotos.isNotEmpty) ...[
            const SizedBox(height: 14),
            _DuringPhotosButton(
              label: _duringPhotosLabel(context, project.duringPhotos.length),
              onTap: () => _openDuringPhotosSheet(context, project),
            ),
          ],
          const SizedBox(height: 14),
          _SectionCard(
            title: _tr(context, 'Notes', 'Notes', 'Notas', 'Notas'),
            trailing: IconButton(
              onPressed: () => _openEditNotesSheet(project),
              icon: const Icon(Icons.edit_rounded),
              tooltip: _tr(context, 'Modifier', 'Edit', 'Editar', 'Editar'),
            ),
            child: Column(
              children: [
                _InfoLine(
                  label: AppStrings.before,
                  value: project.beforeNote.isEmpty
                      ? _tr(context, 'Aucune note', 'No note', 'Sin nota', 'Sem nota')
                      : project.beforeNote,
                ),
                const SizedBox(height: 12),
                _InfoLine(
                  label: AppStrings.after,
                  value: project.afterNote.isEmpty
                      ? _tr(context, 'Aucune note', 'No note', 'Sin nota', 'Sem nota')
                      : project.afterNote,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: _tr(context, 'Informations', 'Information', 'Información', 'Informações'),
            child: Column(
              children: [
                _InfoLine(
                  label: _tr(context, 'Date création', 'Creation date', 'Fecha de creación', 'Data de criação'),
                  value: LocalFiles.formatDate(project.createdAt),
                ),
                const SizedBox(height: 12),
                _InfoLine(
                  label: _tr(context, 'Date après', 'After date', 'Fecha final', 'Data depois'),
                  value: _dateLabel(context, project.afterDate),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: project.status == ProjectStatus.inProgress
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton.icon(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      showDragHandle: true,
                      builder: (_) => _CompleteProjectSheet(project: project),
                    );
                  },
                  icon: const Icon(Icons.add_photo_alternate_rounded),
                  label: Text(_tr(context, 'Compléter', 'Complete', 'Completar', 'Completar')),
                ),
              ),
            )
          : null,
    );
  }
}

class _GalleryImageItem {
  const _GalleryImageItem({
    required this.path,
    required this.title,
  });

  final String path;
  final String title;
}

class _DoubleTapZoomImage extends StatefulWidget {
  const _DoubleTapZoomImage({
    required this.imagePath,
  });

  final String imagePath;

  @override
  State<_DoubleTapZoomImage> createState() => _DoubleTapZoomImageState();
}

class _DoubleTapZoomImageState extends State<_DoubleTapZoomImage> {
  final TransformationController _controller = TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_controller.value != Matrix4.identity()) {
      _controller.value = Matrix4.identity();
      return;
    }

    final details = _doubleTapDetails;
    if (details == null) return;

    final position = details.localPosition;
    const zoom = 2.5;

    final matrix = Matrix4.identity()
      ..translateByDouble(
        -position.dx * (zoom - 1),
        -position.dy * (zoom - 1),
        0,
        1,
      )
      ..scaleByDouble(zoom, zoom, 1, 1);

    _controller.value = matrix;
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.imagePath);

    if (!file.existsSync()) {
      return Center(
        child: Text(
          AppStrings.brokenImage,
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    return GestureDetector(
      onDoubleTapDown: (details) {
        _doubleTapDetails = details;
      },
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _controller,
        minScale: 1,
        maxScale: 4,
        child: Center(
          child: Image.file(
            file,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Text(
                  AppStrings.brokenImage,
                  style: const TextStyle(color: Colors.white70),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SingleImageViewerScreen extends StatelessWidget {
  const _SingleImageViewerScreen({
    required this.title,
    required this.imagePath,
  });

  final String title;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: _DoubleTapZoomImage(imagePath: imagePath),
    );
  }
}

class _FullscreenGalleryScreen extends StatefulWidget {
  const _FullscreenGalleryScreen({
    required this.items,
    this.initialIndex = 0,
  });

  final List<_GalleryImageItem> items;
  final int initialIndex;

  @override
  State<_FullscreenGalleryScreen> createState() => _FullscreenGalleryScreenState();
}

class _FullscreenGalleryScreenState extends State<_FullscreenGalleryScreen> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.items.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.items[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(item.title),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.items.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return _DoubleTapZoomImage(
                imagePath: widget.items[index].path,
              );
            },
          ),
          if (widget.items.length > 1)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.items.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _DuringPhotosButton extends StatelessWidget {
  const _DuringPhotosButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : colorScheme.primary.withValues(alpha: 0.10),
          ),
          child: Icon(
            Icons.photo_library_outlined,
            color: isDark ? Colors.white : colorScheme.primary,
          ),
        ),
        title: Text(
          label,
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
    );
  }
}

class _DuringPhotosSheet extends StatelessWidget {
  const _DuringPhotosSheet({
    required this.project,
    required this.onOpenGallery,
    required this.onOpenSingle,
    required this.onEditDuringPhoto,
  });

  final PhotoProject project;
  final void Function(
    BuildContext context,
    List<_GalleryImageItem> items, {
    int initialIndex,
  }) onOpenGallery;
  final void Function(
    BuildContext context, {
    required String title,
    required String path,
  }) onOpenSingle;
  final void Function(DuringPhoto duringPhoto) onEditDuringPhoto;

  String _tr(
    BuildContext context,
    String fr,
    String en, [
    String? es,
    String? pt,
  ]) {
    final locale = Localizations.localeOf(context);

    switch (locale.languageCode) {
      case 'fr':
        return fr;
      case 'es':
        return es ?? en;
      case 'pt':
        return pt ?? en;
      default:
        return en;
    }
  }

  String _stepTitle(BuildContext context, int index) {
    return _tr(context, 'Étape ${index + 1}', 'Step ${index + 1}', 'Paso ${index + 1}', 'Etapa ${index + 1}');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
                Expanded(
                  child: Text(
                    _tr(context, 'Photos intermédiaires', 'Intermediate photos', 'Fotos intermedias', 'Fotos intermediárias'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                ...project.duringPhotos.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final stepTitle = _stepTitle(context, index);

                  return _DuringSectionCard(
                    title: stepTitle,
                    item: item,
                    onTapImage: () {
                      onOpenSingle(
                        context,
                        title: stepTitle,
                        path: item.path,
                      );
                    },
                    onEdit: () => onEditDuringPhoto(item),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DuringSectionCard extends StatelessWidget {
  const _DuringSectionCard({
    required this.title,
    required this.item,
    this.onTapImage,
    this.onEdit,
  });

  final String title;
  final DuringPhoto item;
  final VoidCallback? onTapImage;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return _ImageSection(
      title: title,
      imagePath: item.path,
      note: item.note,
      allowEmpty: false,
      extraText: item.date != null ? LocalFiles.formatDate(item.date!) : null,
      onTapImage: onTapImage,
      onEdit: onEdit,
    );
  }
}

class _ImageSection extends StatelessWidget {
  const _ImageSection({
    required this.title,
    required this.imagePath,
    required this.note,
    required this.allowEmpty,
    this.extraText,
    this.compact = false,
    this.onTapImage,
    this.onEdit,
  });

  final String title;
  final String imagePath;
  final String note;
  final bool allowEmpty;
  final String? extraText;
  final bool compact;
  final VoidCallback? onTapImage;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final exists = LocalFiles.fileExists(imagePath);
    final colorScheme = Theme.of(context).colorScheme;

    final imageWidget = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: (!exists && allowEmpty)
          ? Container(
              color: colorScheme.onSurface.withValues(alpha: 0.05),
              child: Center(
                child: Text(
                  AppStrings.noPhoto,
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ),
            )
          : Container(
              color: colorScheme.onSurface.withValues(alpha: 0.04),
              child: Image.file(
                File(imagePath),
                fit: compact ? BoxFit.contain : BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
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
              ),
            ),
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            if (onEdit != null)
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
                tooltip: Localizations.localeOf(context).languageCode == 'fr'
                    ? 'Modifier'
                    : Localizations.localeOf(context).languageCode == 'es'
                        ? 'Editar'
                        : Localizations.localeOf(context).languageCode == 'pt'
                            ? 'Editar'
                            : 'Edit',
              ),
          ],
        ),
        const SizedBox(height: 10),
        AspectRatio(
          aspectRatio: 16 / 9,
          child: exists && onTapImage != null
              ? GestureDetector(
                  onTap: onTapImage,
                  child: imageWidget,
                )
              : imageWidget,
        ),
        if (extraText != null && extraText!.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            extraText!,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
        ],
        if (note.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            note,
            style: TextStyle(
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ],
    );

    if (compact) return content;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: content,
      ),
    );
  }
}

class _EditProjectNotesSheet extends StatefulWidget {
  const _EditProjectNotesSheet({
    required this.project,
  });

  final PhotoProject project;

  @override
  State<_EditProjectNotesSheet> createState() => _EditProjectNotesSheetState();
}

class _EditProjectNotesSheetState extends State<_EditProjectNotesSheet> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _beforeNoteController;
  late final TextEditingController _afterNoteController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.project.description,
    );
    _beforeNoteController = TextEditingController(
      text: widget.project.beforeNote,
    );
    _afterNoteController = TextEditingController(
      text: widget.project.afterNote,
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _beforeNoteController.dispose();
    _afterNoteController.dispose();
    super.dispose();
  }

  String _tr(
    String fr,
    String en, [
    String? es,
    String? pt,
  ]) {
    final locale = Localizations.localeOf(context);

    switch (locale.languageCode) {
      case 'fr':
        return fr;
      case 'es':
        return es ?? en;
      case 'pt':
        return pt ?? en;
      default:
        return en;
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await context.read<AppProvider>().updateProjectNotes(
            widget.project.id,
            description: _descriptionController.text.trim(),
            beforeNote: _beforeNoteController.text.trim(),
            afterNote: _afterNoteController.text.trim(),
          );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              'Erreur lors de l’enregistrement : $e',
              'Error while saving: $e',
              'Error al guardar: $e',
              'Erro ao salvar: $e',
            ),
          ),
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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
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
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  Expanded(
                    child: Text(
                      _tr('Modifier les notes', 'Edit notes', 'Editar notas', 'Editar notas'),
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
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: _tr('Description', 'Description', 'Descripción', 'Descrição'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _beforeNoteController,
                maxLines: 3,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: AppStrings.before,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _afterNoteController,
                maxLines: 3,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: AppStrings.after,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(AppStrings.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditDuringPhotoSheet extends StatefulWidget {
  const _EditDuringPhotoSheet({
    required this.projectId,
    required this.duringPhoto,
  });

  final String projectId;
  final DuringPhoto duringPhoto;

  @override
  State<_EditDuringPhotoSheet> createState() => _EditDuringPhotoSheetState();
}

class _EditDuringPhotoSheetState extends State<_EditDuringPhotoSheet> {
  late final TextEditingController _noteController;
  DateTime? _date;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.duringPhoto.note);
    _date = widget.duringPhoto.date;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _tr(
    String fr,
    String en, [
    String? es,
    String? pt,
  ]) {
    final locale = Localizations.localeOf(context);

    switch (locale.languageCode) {
      case 'fr':
        return fr;
      case 'es':
        return es ?? en;
      case 'pt':
        return pt ?? en;
      default:
        return en;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      _date = picked;
    });
  }

  String _dateText() {
    if (_date == null) {
      return _tr('Choisir une date', 'Choose a date', 'Elegir una fecha', 'Escolher uma data');
    }
    return LocalFiles.formatDate(_date!);
  }

  Future<void> _save() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await context.read<AppProvider>().updateDuringPhoto(
            widget.projectId,
            widget.duringPhoto.id,
            note: _noteController.text.trim(),
            date: _date,
          );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              'Erreur lors de l’enregistrement : $e',
              'Error while saving: $e',
              'Error al guardar: $e',
              'Erro ao salvar: $e',
            ),
          ),
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      child: Padding(
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
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  Expanded(
                    child: Text(
                      _tr('Modifier la photo intermédiaire', 'Edit intermediate photo', 'Editar foto intermedia', 'Editar foto intermediária'),
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
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(widget.duringPhoto.path),
                    fit: BoxFit.cover,
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
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month_rounded),
                label: Text(_dateText()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                maxLines: 3,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: AppStrings.note,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(AppStrings.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompleteDuringDraft {
  _CompleteDuringDraft({
    required this.noteController,
  });

  XFile? xfile;
  DateTime? date;
  final TextEditingController noteController;

  void dispose() {
    noteController.dispose();
  }
}

class _CompleteProjectSheet extends StatefulWidget {
  const _CompleteProjectSheet({
    required this.project,
  });

  final PhotoProject project;

  @override
  State<_CompleteProjectSheet> createState() => _CompleteProjectSheetState();
}

class _CompleteProjectSheetState extends State<_CompleteProjectSheet> {
  final ImagePicker _picker = ImagePicker();

  XFile? _afterXFile;
  DateTime? _afterDate;

  late final TextEditingController _afterNoteController;
  final List<_CompleteDuringDraft> _duringDrafts = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _afterNoteController = TextEditingController(text: widget.project.afterNote);
    _afterDate = widget.project.afterDate;
  }

  @override
  void dispose() {
    _afterNoteController.dispose();
    for (final item in _duringDrafts) {
      item.dispose();
    }
    super.dispose();
  }

  String _tr(
    String fr,
    String en, [
    String? es,
    String? pt,
  ]) {
    final locale = Localizations.localeOf(context);

    switch (locale.languageCode) {
      case 'fr':
        return fr;
      case 'es':
        return es ?? en;
      case 'pt':
        return pt ?? en;
      default:
        return en;
    }
  }

  String _stepTitle(int index) {
    return _tr('Étape ${index + 1}', 'Step ${index + 1}', 'Paso ${index + 1}', 'Etapa ${index + 1}');
  }

  Future<XFile?> _cropPickedFile(XFile picked) async {
    final croppedPath = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => CropImageScreen(
          sourcePath: picked.path,
          title: _tr('Rogner la photo', 'Crop image', 'Recortar la foto', 'Recortar a foto'),
          aspectRatio: 16 / 9,
        ),
      ),
    );

    if (croppedPath == null || croppedPath.trim().isEmpty) {
      return null;
    }

    return XFile(croppedPath);
  }

  String _sheetTitle() {
    return _tr('Compléter le projet', 'Complete project', 'Completar el proyecto', 'Completar o projeto');
  }

  String _duringButtonLabel() {
    final count = _duringDrafts.where((e) => e.xfile != null).length;
    return _tr(
      'Photos intermédiaires ($count)',
      'Intermediate photos ($count)',
      'Fotos intermedias ($count)',
      'Fotos intermediárias ($count)',
    );
  }

  void _addDuringDraft() {
    _duringDrafts.add(
      _CompleteDuringDraft(noteController: TextEditingController()),
    );
  }

  void _removeDuringDraftAt(int index) {
    _duringDrafts[index].dispose();
    _duringDrafts.removeAt(index);
  }

  Future<void> _pickImage(String label, ImageSource source, {int? duringIndex}) async {
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
      if (label == 'after') _afterXFile = cropped;
      if (label == 'during' && duringIndex != null) {
        _duringDrafts[duringIndex].xfile = cropped;
      }
    });
  }

  Future<void> _pickDate({
    required void Function(DateTime) onSelected,
    DateTime? initial,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      onSelected(picked);
    }
  }

  Future<void> _openDuringPhotosEditor() async {
    if (_duringDrafts.isEmpty) {
      setState(() {
        _addDuringDraft();
      });
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
                      children: [
                        Text(
                          _stepTitle(index),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
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
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await _pickImage(
                                'during',
                                ImageSource.camera,
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
                                'during',
                                ImageSource.gallery,
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
                      aspectRatio: 16 / 9,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _preview(item.xfile),
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
                    const SizedBox(height: 10),
                    TextField(
                      controller: item.noteController,
                      maxLines: 2,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        labelText: AppStrings.note,
                        labelStyle: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.86),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final bottomInset = MediaQuery.of(context).viewInsets.bottom;

          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16 + bottomInset + MediaQuery.of(context).padding.bottom,
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
                          _tr('Photos intermédiaires', 'Intermediate photos', 'Fotos intermedias', 'Fotos intermediárias'),
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
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _addDuringDraft();
                      });
                      setSheetState(() {});
                    },
                    icon: const Icon(Icons.add_photo_alternate_rounded),
                    label: Text(_tr('Ajouter une photo', 'Add a photo', 'Añadir una foto', 'Adicionar uma foto')),
                  ),
                  const SizedBox(height: 12),
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

  Future<void> _save() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final folder = LocalFiles.folderFromBeforePath(widget.project.beforePath);
      if (folder == null || !folder.existsSync()) {
        if (!mounted) return;
        Navigator.of(context).pop();
        return;
      }

      String? afterPath;
      if (_afterXFile != null) {
        afterPath = await LocalFiles.copyXFileToProject(
          folder,
          _afterXFile!,
          'after',
        );
      }

      final additionalDuring = <DuringPhoto>[];
      int startIndex = widget.project.duringPhotos.length + 1;

      for (final item in _duringDrafts) {
        if (item.xfile == null) continue;

        final label = 'during_$startIndex';
        final path = await LocalFiles.copyXFileToProject(
          folder,
          item.xfile!,
          label,
        );

        additionalDuring.add(
          DuringPhoto(
            id: label,
            path: path,
            note: item.noteController.text.trim(),
            date: item.date,
          ),
        );

        startIndex++;
      }

      await context.read<AppProvider>().updateProjectCompletion(
            widget.project.id,
            afterPath: afterPath,
            afterDate: _afterDate,
            afterNote: _afterNoteController.text.trim(),
            additionalDuringPhotos: additionalDuring,
          );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _preview(XFile? file) {
    final colorScheme = Theme.of(context).colorScheme;

    return file == null
        ? Container(
            color: colorScheme.onSurface.withValues(alpha: 0.05),
            child: Center(
              child: Text(
                AppStrings.preview,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ),
          )
        : Image(
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

  String _dateText(DateTime? date) {
    if (date == null) {
      return _tr('Choisir une date', 'Choose a date', 'Elegir una fecha', 'Escolher uma data');
    }
    return LocalFiles.formatDate(date);
  }

  Widget _afterBlock() {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  AppStrings.after,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage('after', ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_rounded),
                    label: Text(AppStrings.camera),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage('after', ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: Text(AppStrings.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _preview(_afterXFile),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _pickDate(
                initial: _afterDate,
                onSelected: (value) {
                  setState(() {
                    _afterDate = value;
                  });
                },
              ),
              icon: const Icon(Icons.calendar_month_rounded),
              label: Text(_dateText(_afterDate)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _afterNoteController,
              maxLines: 2,
              style: TextStyle(
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                labelText: AppStrings.note,
                labelStyle: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.86),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16 + bottomInset + bottomSafe,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  Expanded(
                    child: Text(
                      _sheetTitle(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _afterBlock(),
                    Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: _openDuringPhotosEditor,
                        leading: const Icon(Icons.photo_library_outlined),
                        title: Text(
                          _duringButtonLabel(),
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
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(AppStrings.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}