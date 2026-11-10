import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/photo_project.dart';

enum ShareAccent { sage, terracotta, blue, lavender, sand, charcoal }

extension ShareAccentColor on ShareAccent {
  Color get color => switch (this) {
    ShareAccent.sage => const Color(0xFF779982),
    ShareAccent.terracotta => const Color(0xFFC77F67),
    ShareAccent.blue => const Color(0xFF6D9FAE),
    ShareAccent.lavender => const Color(0xFF9A8ABD),
    ShareAccent.sand => const Color(0xFFB79A68),
    ShareAccent.charcoal => const Color(0xFF555963),
  };
}
enum ShareFormat { square, portrait, story }

class ProjectShareOptions {
  const ProjectShareOptions({
    this.accent = ShareAccent.sage,
    this.format = ShareFormat.portrait,
    this.beforeNote = true,
    this.afterNote = true,
    this.description = true,
    this.duringNotes = true,
    this.duringIds = const {},
  });
  final ShareAccent accent;
  final ShareFormat format;
  final bool beforeNote, afterNote, description, duringNotes;
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
    const bg = Color(0xFFFAFAF8);
    const card = Colors.white;
    const ink = Color(0xFF292929);
    const muted = Color(0xFF626262);
    final accent = options.accent.color;
    final steps = project.duringPhotos.where((p) =>
      options.duringIds.contains(p.id) && File(p.path).existsSync()).toList();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, h));
    canvas.drawColor(bg, BlendMode.src);
    const margin = 42.0;
    const gap = 18.0;
    final colWidth = (w - 2 * margin - gap) / 2;
    double y = 44;
    _text(canvas, project.title.trim().isEmpty ? 'Avant / Après' : project.title,
      margin, y, w - margin * 2, 46, ink,
      bold: true, maxLines: 2, align: TextAlign.center);
    y += 118;

    final hasNotes = (options.beforeNote && project.beforeNote.trim().isNotEmpty) ||
        (options.afterNote && project.afterNote.trim().isNotEmpty);
    final hasDescription = options.description && project.description.trim().isNotEmpty;
    // Allocate remaining height to photos, steps and explanatory text.
    const footerSpace = 90.0;
    final descSpace = hasDescription ? 145.0 : 0.0;
    final stepSpace = steps.isNotEmpty ? (steps.length <= 2 ? 260.0 : 350.0) : 0.0;
    final noteSpace = hasNotes ? 100.0 : 0.0;
    final available = h - y - footerSpace - descSpace - stepSpace - noteSpace - 25;
    final photoHeight = available.clamp(270.0, options.format == ShareFormat.story ? 1000.0 : 740.0).toDouble();
    final photoY = y;
    for (var i = 0; i < 2; i++) {
      final x = margin + i * (colWidth + gap);
      _rounded(canvas, Rect.fromLTWH(x, photoY, colWidth, photoHeight + (hasNotes ? noteSpace : 0)), card, 22);
      final image = await _load(i == 0 ? project.beforePath : project.afterPath);
      _cover(canvas, image, Rect.fromLTWH(x, photoY, colWidth, photoHeight - 2), 20);
      _pill(canvas, i == 0 ? 'AVANT' : 'APRÈS', x + 20, photoY + photoHeight - 66, accent);
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
      final rowHeight = ((stepSpace - 54) / rows).clamp(95.0, 225.0).toDouble();
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

    canvas.drawRect(Rect.fromLTWH(margin, h - 82, w - margin * 2, 2),
      Paint()..color = accent.withValues(alpha: 0.30));
    _text(canvas, 'Avant / Après  ·  Application mobile', margin, h - 64,
      w - margin * 2, 23, muted, align: TextAlign.center);

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

  static void _pill(Canvas canvas, String label, double x, double y, Color accent) {
    _rounded(canvas, Rect.fromLTWH(x, y, 146, 46), accent, 15);
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
