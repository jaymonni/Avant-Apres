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
  int _exportFormat = 0;

  double get _exportRatio => switch (_exportFormat) {
    1 => 1.0,
    2 => 4 / 5,
    3 => 9 / 16,
    _ => 4 / 5,
  };
  bool _busy = false;
  double _split = 0.5;
  bool _adjust = false;
  bool _editBefore = true;
  Offset _palettePosition = const Offset(12, 80);
  String? _beforeLabel;
  String? _afterLabel;
  bool _labelsAtBottom = false;
  int _labelColor = 0;

  String get _beforeText => _beforeLabel ?? AppStrings.before;
  String get _afterText => _afterLabel ?? AppStrings.after;
  Color get _labelBackground => const [
    Colors.black87, Color(0xFF1565C0), Color(0xFF2E7D32),
    Color(0xFFAD1457),
  ][_labelColor];

  Future<void> _editLabels() async {
    var beforeText = _beforeText;
    var afterText = _afterText;
    var bottom = _labelsAtBottom;
    var color = _labelColor;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, updateSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20,
            MediaQuery.viewInsetsOf(sheetContext).bottom + 20),
          child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_tr('Personnaliser les étiquettes', 'Customize labels',
                'Personalizar etiquetas', 'Personalizar etiquetas'),
                style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(initialValue: beforeText, maxLength: 24,
                onChanged: (value) => beforeText = value,
                decoration: InputDecoration(labelText: AppStrings.before,
                  border: const OutlineInputBorder())),
              const SizedBox(height: 8),
              TextFormField(initialValue: afterText, maxLength: 24,
                onChanged: (value) => afterText = value,
                decoration: InputDecoration(labelText: AppStrings.after,
                  border: const OutlineInputBorder())),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_tr('Étiquettes en bas', 'Labels at bottom',
                  'Etiquetas abajo', 'Etiquetas em baixo')),
                value: bottom,
                onChanged: (value) => updateSheet(() => bottom = value),
              ),
              Text(_tr('Couleur', 'Color', 'Color', 'Cor')),
              const SizedBox(height: 8),
              Wrap(spacing: 12, children: [
                for (var i = 0; i < 4; i++)
                  IconButton.filled(
                    tooltip: '${i + 1}',
                    style: IconButton.styleFrom(
                      backgroundColor: const [Colors.black87,
                        Color(0xFF1565C0), Color(0xFF2E7D32),
                        Color(0xFFAD1457)][i]),
                    onPressed: () => updateSheet(() => color = i),
                    icon: Icon(color == i ? Icons.check : Icons.circle_outlined,
                      color: Colors.white),
                  ),
              ]),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: FilledButton(
                onPressed: () {
                  setState(() {
                    _beforeLabel = beforeText.trim().isEmpty
                        ? null : beforeText.trim();
                    _afterLabel = afterText.trim().isEmpty
                        ? null : afterText.trim();
                    _labelsAtBottom = bottom;
                    _labelColor = color;
                  });
                  Navigator.pop(sheetContext);
                },
                child: Text(_tr('Appliquer', 'Apply', 'Aplicar', 'Aplicar')),
              )),
            ],
          )),
        ),
      ),
    );
  }
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

  void _nudge(double dx, double dy) {
    final controller = _editBefore ? _beforeController : _afterController;
    final matrix = controller.value.clone();
    matrix.setTranslationRaw(
      matrix.entry(0, 3) + dx,
      matrix.entry(1, 3) + dy,
      matrix.entry(2, 3),
    );
    controller.value = matrix;
    setState(() {});
  }

  Widget _fusionControls() {
    final colors = Theme.of(context).colorScheme;
    final small = Theme.of(context).textTheme.bodySmall;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) {
            final area = MediaQuery.sizeOf(context);
            setState(() => _palettePosition = Offset(
              (_palettePosition.dx + details.delta.dx).clamp(0.0, (area.width - 292).clamp(0.0, double.infinity)),
              (_palettePosition.dy + details.delta.dy).clamp(0.0, (area.height - 420).clamp(0.0, double.infinity)),
            ));
          },
          child: Row(children: [
            Icon(Icons.drag_indicator_rounded, color: colors.primary, size: 22),
            const SizedBox(width: 6),
            Expanded(child: Text(_tr('Ajuster la photo', 'Adjust photo', 'Ajustar foto', 'Ajustar foto'),
              style: Theme.of(context).textTheme.titleSmall)),
            IconButton(
              tooltip: _tr('Fermer', 'Close', 'Cerrar', 'Fechar'),
              onPressed: () => setState(() => _adjust = false),
              icon: const Icon(Icons.close_rounded),
            ),
          ]),
        ),
        const SizedBox(height: 6),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: true, label: Text(AppStrings.before)),
            ButtonSegment(value: false, label: Text(AppStrings.after)),
          ],
          selected: {_editBefore},
          onSelectionChanged: (value) => setState(() => _editBefore = value.first),
        ),
        const SizedBox(height: 8),
        Divider(color: colors.outlineVariant, height: 1),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(child: Column(children: [
            Text(_tr('Zoom', 'Zoom', 'Zoom', 'Zoom'), style: small),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton.filledTonal(
                tooltip: _tr('Dézoomer', 'Zoom out', 'Alejar', 'Diminuir zoom'),
                onPressed: () => _zoom(0.8), icon: const Icon(Icons.remove)),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                tooltip: _tr('Zoomer', 'Zoom in', 'Acercar', 'Aumentar zoom'),
                onPressed: () => _zoom(1.25), icon: const Icon(Icons.add)),
            ]),
          ])),
          const SizedBox(width: 8),
          Expanded(child: Column(children: [
            Text(_tr('Déplacement', 'Move', 'Mover', 'Mover'), style: small),
            SizedBox(height: 40, width: 40, child: IconButton.filledTonal(
              padding: EdgeInsets.zero,
              tooltip: _tr('Haut', 'Up', 'Arriba', 'Cima'),
              onPressed: () => _nudge(0, -12),
              icon: const Icon(Icons.keyboard_arrow_up_rounded),
            )),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (final direction in <(IconData, double, double)>[
                (Icons.keyboard_arrow_left_rounded, -12, 0),
                (Icons.keyboard_arrow_down_rounded, 0, 12),
                (Icons.keyboard_arrow_right_rounded, 12, 0),
              ])
                SizedBox(width: 40, height: 40, child: IconButton.filledTonal(
                  padding: EdgeInsets.zero,
                  tooltip: direction.$1 == Icons.keyboard_arrow_left_rounded
                      ? _tr('Gauche', 'Left', 'Izquierda', 'Esquerda')
                      : direction.$1 == Icons.keyboard_arrow_down_rounded
                          ? _tr('Bas', 'Down', 'Abajo', 'Baixo')
                          : _tr('Droite', 'Right', 'Derecha', 'Direita'),
                  onPressed: () => _nudge(direction.$2, direction.$3),
                  icon: Icon(direction.$1),
                )),
            ]),
          ])),
        ]),
      ]),
    );
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
        top: _labelsAtBottom ? null : 10,
        bottom: _labelsAtBottom ? 10 : null,
        left: 10,
        child: DecoratedBox(
          decoration: BoxDecoration(color: _labelBackground, borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    ]));
  }

  Widget _comparison() {
    final first = _image(_before, _beforeText, _beforeController);
    final second = _image(_after, _afterText, _afterController);
    if (_layout == 1) {
      return Column(children: [first, const SizedBox(height: 3), second]);
    }
    if (_layout == 2 && _before != null && _after != null) {
      return LayoutBuilder(builder: (context, size) {
        final divider = size.maxWidth * _split;
        return Stack(fit: StackFit.expand, children: [
          IgnorePointer(
            ignoring: !_adjust || !_editBefore,
            child: ClipRect(
              clipper: _SplitClipper(_split, showLeft: true),
              child: _editable(_before!, _beforeController),
            ),
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
          Positioned(top: _labelsAtBottom ? null : 10, bottom: _labelsAtBottom ? 10 : null, left: 10, child: _fusionLabel(_beforeText)),
          Positioned(top: _labelsAtBottom ? null : 10, bottom: _labelsAtBottom ? 10 : null, right: 10, child: _fusionLabel(_afterText)),
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
      color: _labelBackground,
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
        child: Stack(children: [
          ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                aspectRatio: _exportRatio,
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
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.aspect_ratio_rounded, size: 20),
            const SizedBox(width: 8),
            Text(_tr('Format de sortie', 'Output format',
              'Formato de salida', 'Formato de saída'),
              style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(width: 12),
            Expanded(child: DropdownButtonFormField<int>(
              value: _exportFormat,
              isExpanded: true,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              ),
              items: [
                DropdownMenuItem(value: 0,
                  child: Text(_tr('Original (4:5)', 'Original (4:5)',
                    'Original (4:5)', 'Original (4:5)'))),
                const DropdownMenuItem(value: 1, child: Text('Carré · 1:1')),
                const DropdownMenuItem(value: 2, child: Text('Portrait · 4:5')),
                const DropdownMenuItem(value: 3, child: Text('Story · 9:16')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _exportFormat = value);
              },
            )),
          ]),
          const SizedBox(height: 16),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: 0, label: Text(_tr('Côte à côte', 'Side by side', 'Lado a lado', 'Lado a lado'))),
              ButtonSegment(value: 1, label: Text(_tr('Haut / Bas', 'Top / Bottom', 'Arriba / Abajo', 'Cima / Baixo'))),
              ButtonSegment(value: 2, label: Text(_tr('Fusion 50/50', '50/50 blend', 'Fusión 50/50', 'Fusão 50/50'))),
            ],
            selected: {_layout},
            onSelectionChanged: (value) => setState(() => _layout = value.first),
          ),
          if (ready)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: _editLabels,
                  icon: const Icon(Icons.text_fields_rounded),
                  label: Text(_tr('Texte', 'Text', 'Texto', 'Texto')),
                )),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => setState(() => _adjust = !_adjust),
                  icon: Icon(_adjust ? Icons.close_rounded : Icons.tune_rounded),
                  label: Text(_adjust
                    ? _tr('Fermer', 'Close', 'Cerrar', 'Fechar')
                    : _tr('Ajuster', 'Adjust', 'Ajustar', 'Ajustar')),
                )),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: _tr('Réinitialiser', 'Reset', 'Restablecer', 'Repor'),
                  onPressed: () {
                    _beforeController.value = Matrix4.identity();
                    _afterController.value = Matrix4.identity();
                    setState(() => _split = 0.5);
                  },
                  icon: const Icon(Icons.restart_alt_rounded),
                ),
              ]),
            ),
        ],
        ),
          if (ready && _adjust)
            Positioned(
              left: _palettePosition.dx,
              top: _palettePosition.dy,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(width: 288, child: _fusionControls()),
              ),
            ),
        ]),
      ),
    );
  }
}

class _SplitClipper extends CustomClipper<Rect> {
  const _SplitClipper(this.split, {this.showLeft = false});
  final double split;
  final bool showLeft;
  @override
  Rect getClip(Size size) => showLeft
      ? Rect.fromLTRB(0, 0, size.width * split, size.height)
      : Rect.fromLTRB(size.width * split, 0, size.width, size.height);
  @override
  bool shouldReclip(covariant _SplitClipper oldClipper) =>
      split != oldClipper.split || showLeft != oldClipper.showLeft;
}
