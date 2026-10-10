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
        if (before) { _before = file; } else { _after = file; }
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
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(AppStrings.gallery),
            onTap: () { Navigator.pop(sheetContext); _pick(before, ImageSource.gallery); },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: Text(AppStrings.camera),
            onTap: () { Navigator.pop(sheetContext); _pick(before, ImageSource.camera); },
          ),
        ]),
      ),
    );
  }

  Widget _image(XFile? file, String label) {
    return Expanded(child: Stack(fit: StackFit.expand, children: [
      if (file != null)
        Image.file(File(file.path), fit: BoxFit.contain)
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
    final first = _image(_before, AppStrings.before);
    final second = _image(_after, AppStrings.after);
    if (_layout == 1) {
      return Column(children: [first, const SizedBox(height: 3), second]);
    }
    if (_layout == 2 && _before != null && _after != null) {
      return Stack(fit: StackFit.expand, children: [
        Image.file(File(_before!.path), fit: BoxFit.contain),
        ClipPath(
          clipper: _RightHalfClipper(),
          child: Image.file(File(_after!.path), fit: BoxFit.contain),
        ),
        const Center(child: VerticalDivider(width: 2, thickness: 2, color: Colors.white)),
        Positioned(top: 10, left: 10, child: _fusionLabel(AppStrings.before)),
        Positioned(top: 10, right: 10, child: _fusionLabel(AppStrings.after)),
      ]);
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
      body: ListView(
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
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: ready && !_busy ? _share : null,
            icon: const Icon(Icons.share),
            label: Text(_busy
                ? _tr('Préparation...', 'Preparing...', 'Preparando...', 'Preparando...')
                : _tr('Partager la comparaison', 'Share comparison',
                    'Compartir comparación', 'Compartilhar comparação')),
          ),
        ],
      ),
    );
  }
}

class _RightHalfClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..addRect(Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height));

  @override
  bool shouldReclip(covariant _RightHalfClipper oldClipper) => false;
}
