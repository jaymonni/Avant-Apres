import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_strings.dart';

class ExpressScreen extends StatefulWidget {
  const ExpressScreen({super.key});

  @override
  State<ExpressScreen> createState() => _ExpressScreenState();
}

class _ExpressScreenState extends State<ExpressScreen> {
  final _picker = ImagePicker();
  final _captureKey = GlobalKey();
  XFile? _before;
  XFile? _after;
  int _layout = 0;
  bool _busy = false;
  double _split = 0.5;
  bool _adjust = false;
  bool _editBefore = true;
  final _beforeController = TransformationController();
  final _afterController = TransformationController();

  @override
  void dispose() {
    _beforeController.dispose();
    _afterController.dispose();
    super.dispose();
  }

  Widget _editable(XFile photo, TransformationController controller) => InteractiveViewer(
    transformationController: controller,
    panEnabled: _layout != 2 || _adjust,
    scaleEnabled: _layout != 2 || _adjust,
    boundaryMargin: const EdgeInsets.all(120),
    minScale: 1,
    maxScale: 5,
    child: SizedBox.expand(child: Image.file(File(photo.path), fit: BoxFit.contain)),
  );

  void _zoom(double factor) {
    final controller = _editBefore ? _beforeController : _afterController;
    final matrix = controller.value.clone();
    final current = matrix.getMaxScaleOnAxis();
    final next = (current * factor).clamp(1.0, 5.0);
    controller.value = matrix..scale(next / current);
    setState(() {});
  }

  String _tr(String fr, String en, String es, String pt) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'fr': return fr;
      case 'es': return es;
      case 'pt': return pt;
      default: return en;
    }
  }

  Future<void> _pick(bool before, ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 90);
      if (!mounted || file == null) return;
      setState(() {
        if (before) { _before = file; _beforeController.value = Matrix4.identity(); } else { _after = file; _afterController.value = Matrix4.identity(); }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_tr('Impossible de sélectionner la photo', 'Unable to select photo',
              'No se puede seleccionar la foto', 'Não foi possível selecionar a foto')),
        ));
      }
    }
  }

  Future<void> _choose(bool before) async {
    final colors = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 42),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _tr('Ajouter une photo', 'Add a photo', 'Añadir una foto', 'Adicionar uma foto'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: _photoSourceCard(
              icon: Icons.photo_library_rounded,
              label: AppStrings.gallery,
              onTap: () {
                Navigator.pop(sheetContext);
                _pick(before, ImageSource.gallery);
              },
            )),
            const SizedBox(width: 14),
            Expanded(child: _photoSourceCard(
              icon: Icons.photo_camera_rounded,
              label: AppStrings.camera,
              onTap: () {
                Navigator.pop(sheetContext);
                _pick(before, ImageSource.camera);
              },
            )),
          ]),
        ]),
      ),
    );
  }

  Widget _photoSourceCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.primaryContainer.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
          child: Column(children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: colors.primary,
              child: Icon(icon, color: colors.onPrimary, size: 28),
            ),
            const SizedBox(height: 14),
            Text(label, textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }

  Widget _image(XFile? file, String label, TransformationController controller) {
    final before = controller == _beforeController;
    return Expanded(child: Stack(fit: StackFit.expand, children: [
      if (file != null)
        Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) {
            if (_editBefore != before) setState(() => _editBefore = before);
          },
          child: _editable(file, controller),
        )
      else
        ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Center(child: Icon(Icons.add_photo_alternate_outlined, size: 44)),
        ),
      Positioned(
        top: 10, left: 10,
        child: DecoratedBox(
          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    ]));
  }

  Widget _comparison() {
    final first = _image(_before, AppStrings.before, _beforeController);
    final second = _image(_after, AppStrings.after, _afterController);
    if (_layout == 1) {
      return Column(children: [first, const SizedBox(height: 3), second]);
    }
    if (_layout == 2 && _before != null && _after != null) {
      return LayoutBuilder(builder: (context, size) {
        final divider = size.maxWidth * _split;
        return Stack(fit: StackFit.expand, children: [
          IgnorePointer(
            ignoring: !_adjust || !_editBefore,
            child: _editable(_before!, _beforeController),
          ),
          IgnorePointer(
            ignoring: !_adjust || _editBefore,
            child: ClipRect(
              clipper: _SplitClipper(_split),
              child: _editable(_after!, _afterController),
            ),
          ),
          Positioned(left: divider - 1, top: 0, bottom: 0,
            child: const SizedBox(width: 2, child: ColoredBox(color: Colors.white))),
          Positioned(top: 10, left: 10, child: _fusionLabel(AppStrings.before)),
          Positioned(top: 10, right: 10, child: _fusionLabel(AppStrings.after)),
          if (!_adjust)
            Positioned(
              left: (divider - 24).clamp(0.0, size.maxWidth - 48),
              top: 0, bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: (details) => setState(() {
                  _split = (_split + details.delta.dx / size.maxWidth).clamp(0.05, 0.95);
                }),
                child: Center(child: Container(
                  width: 48, height: 48,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.compare_arrows, color: Colors.black),
                )),
              ),
            ),
        ]);
      });
    }
    return Row(children: [first, const SizedBox(width: 4), second]);
  }

  Widget _fusionLabel(String label) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black87,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(label, style: const TextStyle(
        color: Colors.white, fontWeight: FontWeight.bold,
      )),
    ),
  );

  Future<void> _share() async {
    if (_before == null || _after == null || _busy) return;
    setState(() => _busy = true);
    try {
      final boundary = _captureKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) {
        throw StateError('Preview unavailable');
      }
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('PNG unavailable');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/express_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_tr('Export impossible', 'Export failed', 'Error al exportar', 'Falha ao exportar')),
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = _before != null && _after != null;
    return Scaffold(
      appBar: AppBar(title: Text(_tr('Transformation Express', 'Express Transformation',
          'Transformación exprés', 'Transformação Express'))),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton.icon(
            onPressed: ready && !_busy ? _share : null,
            icon: const Icon(Icons.share),
            label: Text(_busy
                ? _tr('Préparation...', 'Preparing...', 'Preparando...', 'Preparando...')
                : _tr('Partager la comparaison', 'Share comparison',
                    'Compartir comparación', 'Compartilhar comparação')),
          ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.09),
            ],
          ),
        ),
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(_tr('Choisissez deux photos pour créer une comparaison.',
              'Choose two photos to create a comparison.',
              'Elige dos fotos para crear una comparación.',
              'Escolha duas fotos para criar uma comparação.')),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () => _choose(true),
              icon: const Icon(Icons.add_photo_alternate),
              label: Text(AppStrings.before),
            )),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton.icon(
              onPressed: () => _choose(false),
              icon: const Icon(Icons.add_photo_alternate),
              label: Text(AppStrings.after),
            )),
          ]),
          const SizedBox(height: 16),
          Stack(children: [
            RepaintBoundary(
              key: _captureKey,
              child: AspectRatio(
                aspectRatio: 4 / 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _comparison(),
                ),
              ),
            ),
            if (ready && (_layout != 2 || _adjust))
              Positioned.fill(
                child: IgnorePointer(
                  child: Padding(
                    padding: _layout == 2
                        ? EdgeInsets.zero
                        : _layout == 1
                            ? EdgeInsets.fromLTRB(0, _editBefore ? 0 : 0, 0, 0)
                            : EdgeInsets.zero,
                    child: Align(
                      alignment: _layout == 2
                          ? Alignment.center
                          : _layout == 1
                              ? (_editBefore ? Alignment.topCenter : Alignment.bottomCenter)
                              : (_editBefore ? Alignment.centerLeft : Alignment.centerRight),
                      child: FractionallySizedBox(
                        widthFactor: _layout == 2 ? 1 : (_layout == 1 ? 1 : 0.5),
                        heightFactor: _layout == 2 ? 1 : (_layout == 1 ? 0.5 : 1),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).colorScheme.primary, width: 3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 16),
          SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 0, label: Text(_tr('Côte à côte', 'Side by side', 'Lado a lado', 'Lado a lado'))),
              ButtonSegment(value: 1, label: Text(_tr('Haut / Bas', 'Top / Bottom', 'Arriba / Abajo', 'Cima / Baixo'))),
              ButtonSegment(value: 2, label: Text(_tr('Fusion 50/50', '50/50 blend', 'Fusión 50/50', 'Fusão 50/50'))),
            ],
            selected: {_layout},
            onSelectionChanged: (value) => setState(() => _layout = value.first),
          ),
          if (ready && _layout == 2)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _adjust = !_adjust),
                  icon: Icon(_adjust ? Icons.compare_arrows_rounded : Icons.tune_rounded),
                  label: Text(_adjust
                    ? _tr('Déplacer le curseur', 'Move divider', 'Mover divisor', 'Mover divisor')
                    : _tr('Ajuster les photos', 'Adjust photos', 'Ajustar fotos', 'Ajustar fotos')),
                ),
              ),
            ),
          if (ready && (_layout != 2 || _adjust))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(children: [
                Text(_tr('Touchez la photo à ajuster, puis glissez-la ou zoomez.',
                  'Tap the photo to adjust, then drag or zoom.',
                  'Toca la foto, luego arrástrala o amplíala.',
                  'Toque na foto, depois arraste ou amplie.'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(_editBefore ? AppStrings.before : AppStrings.after,
                    style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(width: 18),
                  IconButton.filledTonal(
                    tooltip: _tr('Dézoomer', 'Zoom out', 'Alejar', 'Diminuir zoom'),
                    onPressed: () => _zoom(0.8),
                    icon: const Icon(Icons.remove),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    tooltip: _tr('Zoomer', 'Zoom in', 'Acercar', 'Aumentar zoom'),
                    onPressed: () => _zoom(1.25),
                    icon: const Icon(Icons.add),
                  ),
                ]),
                if (_layout == 2)
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    TextButton(onPressed: () => setState(() => _editBefore = true),
                      child: Text(AppStrings.before)),
                    TextButton(onPressed: () => setState(() => _editBefore = false),
                      child: Text(AppStrings.after)),
                  ]),
              ]),
            ),
          if (ready)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  _beforeController.value = Matrix4.identity();
                  _afterController.value = Matrix4.identity();
                  setState(() => _split = 0.5);
                },
                icon: const Icon(Icons.restart_alt),
                label: Text(_tr('Réinitialiser', 'Reset', 'Restablecer', 'Repor')),
              ),
            ),
        ],
        ),
      ),
    );
  }
}

class _SplitClipper extends CustomClipper<Rect> {
  const _SplitClipper(this.split);
  final double split;
  @override
  Rect getClip(Size size) => Rect.fromLTRB(size.width * split, 0, size.width, size.height);
  @override
  bool shouldReclip(covariant _SplitClipper oldClipper) => split != oldClipper.split;
}
