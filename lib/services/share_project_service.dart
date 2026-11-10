import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/photo_project.dart';

enum ShareTheme { light, modern, dark }
enum ShareFormat { square, portrait, story }

class ProjectShareOptions {
  const ProjectShareOptions({
    this.theme = ShareTheme.modern,
    this.format = ShareFormat.portrait,
    this.beforeNote = true,
    this.afterNote = true,
    this.description = true,
    this.duringNotes = true,
    this.signature = true,
    this.duringIds = const {},
  });
  final ShareTheme theme;
  final ShareFormat format;
  final bool beforeNote, afterNote, description, duringNotes, signature;
  final Set<String> duringIds;
}

class ShareProjectService {
  static Future<void> shareFinishedProject(PhotoProject project, {
    required String shareText,
    ProjectShareOptions options = const ProjectShareOptions(),
  }) async {
    final path = await buildShareImage(project, options);
    await SharePlus.instance.share(ShareParams(
      files: [XFile(path)], text: shareText, subject: project.title,
    ));
  }

  static Future<String> buildShareImage(PhotoProject project, ProjectShareOptions options) async {
    if (!File(project.beforePath).existsSync() || !File(project.afterPath).existsSync()) {
      throw Exception('Photos Avant / Après introuvables');
    }
    const w = 1080.0;
    final h = switch (options.format) {
      ShareFormat.square => 1080.0,
      ShareFormat.portrait => 1350.0,
      ShareFormat.story => 1920.0,
    };
    final bg = switch (options.theme) {
      ShareTheme.light => const Color(0xFFF7F8FA),
      ShareTheme.modern => const Color(0xFFEDF2F6),
      ShareTheme.dark => const Color(0xFF202630),
    };
    final card = options.theme == ShareTheme.dark ? const Color(0xFF303945) : Colors.white;
    final ink = options.theme == ShareTheme.dark ? Colors.white : const Color(0xFF172A3E);
    final muted = options.theme == ShareTheme.dark ? const Color(0xFFCED6DE) : const Color(0xFF526174);
    const accent = Color(0xFF113653);
    final steps = project.duringPhotos.where((p) =>
      options.duringIds.contains(p.id) && File(p.path).existsSync()).toList();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, h));
    canvas.drawColor(bg, BlendMode.src);
    const margin = 42.0;
    const gap = 18.0;
    final colWidth = (w - 2 * margin - gap) / 2;
    double y = 40;
    _text(canvas, project.title.trim().isEmpty ? 'Avant / Après' : project.title,
      margin, y, w - margin * 2, 46, ink, bold: true, maxLines: 2);
    y += 112;

    final hasNotes = (options.beforeNote && project.beforeNote.trim().isNotEmpty) ||
        (options.afterNote && project.afterNote.trim().isNotEmpty);
    final hasDescription = options.description && project.description.trim().isNotEmpty;
    // Allocate remaining height to photos, steps and explanatory text.
    final footerSpace = options.signature ? 74.0 : 28.0;
    final descSpace = hasDescription ? 145.0 : 0.0;
    final stepSpace = steps.isNotEmpty ? (steps.length <= 2 ? 260.0 : 350.0) : 0.0;
    final noteSpace = hasNotes ? 100.0 : 0.0;
    final available = h - y - footerSpace - descSpace - stepSpace - noteSpace - 25;
    final photoHeight = available.clamp(270.0, options.format == ShareFormat.story ? 1000.0 : 740.0);
    final photoY = y;
    for (var i = 0; i < 2; i++) {
      final x = margin + i * (colWidth + gap);
      _rounded(canvas, Rect.fromLTWH(x, photoY, colWidth, photoHeight + (hasNotes ? noteSpace : 0)), card, 22);
      final image = await _load(i == 0 ? project.beforePath : project.afterPath);
      _cover(canvas, image, Rect.fromLTWH(x, photoY, colWidth, photoHeight - 2), 20);
      _pill(canvas, i == 0 ? 'AVANT' : 'APRÈS', x + 20, photoY + photoHeight - 66, ink);
      final note = i == 0 ? project.beforeNote : project.afterNote;
      if (hasNotes && (i == 0 ? options.beforeNote : options.afterNote) && note.trim().isNotEmpty) {
        _text(canvas, note, x + 15, photoY + photoHeight + 12, colWidth - 30, 24, muted, maxLines: 3);
      }
    }
    y += photoHeight + (hasNotes ? noteSpace : 0) + 22;

    if (steps.isNotEmpty) {
      _text(canvas, 'LES ÉTAPES', margin, y, w - margin * 2, 28, ink, bold: true);
      y += 44;
      final columns = steps.length == 1 ? 1 : (steps.length == 2 ? 2 : 3);
      final cellW = (w - margin * 2 - gap * (columns - 1)) / columns;
      final rows = (steps.length / columns).ceil();
      final rowHeight = ((stepSpace - 54) / rows).clamp(95.0, 225.0);
      for (var i = 0; i < steps.length; i++) {
        final row = i ~/ columns;
        final column = i % columns;
        final x = margin + column * (cellW + gap);
        final top = y + row * rowHeight;
        final noteH = options.duringNotes && steps[i].note.trim().isNotEmpty ? 48.0 : 0.0;
        final imgH = rowHeight - noteH - 10;
        final image = await _load(steps[i].path);
        _cover(canvas, image, Rect.fromLTWH(x, top, cellW, imgH), 12);
        if (noteH > 0) _text(canvas, steps[i].note, x + 4, top + imgH + 5, cellW - 8, 19, muted, maxLines: 2);
      }
      y += rows * rowHeight + 14;
    }

    if (hasDescription) {
      _text(canvas, 'LA TRANSFORMATION', margin, y, w - 2 * margin, 27, ink, bold: true);
      y += 40;
      _text(canvas, project.description, margin, y, w - 2 * margin, 25, muted, maxLines: 4);
    }

    if (options.signature) {
      canvas.drawRect(Rect.fromLTWH(0, h - 62, w, 62), Paint()..color = accent);
      _text(canvas, 'Créé avec Avant / Après', margin, h - 48, w - 2 * margin, 24, Colors.white,
        bold: true, align: TextAlign.right);
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(w.toInt(), h.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    if (bytes == null) throw Exception('Impossible de générer le partage');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/project_share_${DateTime.now().microsecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    return file.path;
  }

  static Future<ui.Image> _load(String path) async {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  static void _rounded(Canvas canvas, Rect r, Color color, double radius) {
    canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(radius)), Paint()..color = color);
  }

  static void _cover(Canvas canvas, ui.Image image, Rect dest, double radius) {
    final iw = image.width.toDouble(), ih = image.height.toDouble();
    final ratio = dest.width / dest.height;
    final src = iw / ih > ratio
      ? Rect.fromLTWH((iw - ih * ratio) / 2, 0, ih * ratio, ih)
      : Rect.fromLTWH(0, (ih - iw / ratio) / 2, iw, iw / ratio);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(dest, Radius.circular(radius)));
    canvas.drawImageRect(image, src, dest, Paint()..filterQuality = FilterQuality.high);
    canvas.restore();
    image.dispose();
  }

  static void _pill(Canvas canvas, String label, double x, double y, Color ink) {
    _rounded(canvas, Rect.fromLTWH(x, y, 146, 46), const Color(0xFF113653), 15);
    _text(canvas, label, x + 12, y + 8, 122, 24, Colors.white, bold: true, align: TextAlign.center);
  }

  static void _text(Canvas canvas, String text, double x, double y, double width,
      double size, Color color, {bool bold = false, int maxLines = 1, TextAlign align = TextAlign.left}) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: size, color: color,
        fontWeight: bold ? FontWeight.w800 : FontWeight.w500, height: 1.22)),
      textDirection: TextDirection.ltr, textAlign: align, maxLines: maxLines, ellipsis: '…',
    )..layout(maxWidth: width);
    painter.paint(canvas, Offset(x, y));
    painter.dispose();
  }
}
