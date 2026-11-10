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
    const ink = Color(0xFF292929);
    const muted = Color(0xFF626262);
    final accent = options.accent.color;
    final steps = project.duringPhotos.where((p) =>
      options.duringIds.contains(p.id) && File(p.path).existsSync()).toList();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, h));
    canvas.drawColor(bg, BlendMode.src);
    const margin = 48.0;
    const gap = 20.0;
    const footerTopGap = 28.0;
    const footerHeight = 80.0;
    const titleTop = 44.0;
    const titleArea = 120.0;
    const labelHeight = 43.0;
    const sectionGap = 30.0;
    final colWidth = (w - 2 * margin - gap) / 2;
    final hasNotes = (options.beforeNote && project.beforeNote.trim().isNotEmpty) ||
      (options.afterNote && project.afterNote.trim().isNotEmpty);
    final hasDescription = options.description && project.description.trim().isNotEmpty;
    final noteHeight = hasNotes ? 84.0 : 0.0;
    final descHeight = hasDescription ? 110.0 : 0.0;
    final stepsHeight = steps.isEmpty ? 0.0 :
      (options.format == ShareFormat.square ? 185.0 :
        options.format == ShareFormat.portrait ? 245.0 : 370.0);
    final photoBudget = h - titleTop - titleArea - labelHeight -
      noteHeight - descHeight - stepsHeight - footerHeight -
      footerTopGap - sectionGap - 12;
    final photoHeight = photoBudget.clamp(240.0, 1100.0).toDouble();

    _text(canvas, project.title.trim().isEmpty ? 'Avant / Après' : project.title,
      margin, titleTop, w - margin * 2, 46, ink,
      bold: true, maxLines: 2, align: TextAlign.center);
    double y = titleTop + titleArea;

    for (var i = 0; i < 2; i++) {
      final x = margin + i * (colWidth + gap);
      _text(canvas, i == 0 ? 'AVANT' : 'APRÈS',
        x, y, colWidth, 29, accent, bold: true, align: TextAlign.center);
      final image = await _load(i == 0 ? project.beforePath : project.afterPath);
      _cover(canvas, image,
        Rect.fromLTWH(x, y + labelHeight, colWidth, photoHeight), 16);
      final note = i == 0 ? project.beforeNote : project.afterNote;
      if (hasNotes && (i == 0 ? options.beforeNote : options.afterNote) &&
          note.trim().isNotEmpty) {
        _text(canvas, note, x + 5, y + labelHeight + photoHeight + 12,
          colWidth - 10, 23, muted, maxLines: 2);
      }
    }
    y += labelHeight + photoHeight + noteHeight + sectionGap;

    if (steps.isNotEmpty) {
      _text(canvas, 'LES ÉTAPES', margin, y, w - margin * 2, 26,
        ink, bold: true);
      y += 42;
      final columns = steps.length == 1 ? 1 : 2;
      final rows = (steps.length / columns).ceil();
      final cellW = (w - margin * 2 - gap * (columns - 1)) / columns;
      final rowH = (stepsHeight - 50) / rows;
      for (var i = 0; i < steps.length; i++) {
        final row = i ~/ columns;
        final column = i % columns;
        final x = margin + column * (cellW + gap);
        final top = y + row * rowH;
        final hasStepNote = options.duringNotes && steps[i].note.trim().isNotEmpty;
        final noteH = hasStepNote && rowH >= 95 ? 37.0 : 0.0;
        final imgH = (rowH - noteH - 12).clamp(24.0, rowH).toDouble();
        final image = await _load(steps[i].path);
        _cover(canvas, image, Rect.fromLTWH(x, top, cellW, imgH), 12);
        if (noteH > 0) {
          _text(canvas, steps[i].note, x + 4, top + imgH + 4,
            cellW - 8, 20, muted, maxLines: 1);
        }
      }
      y += stepsHeight - 42;
    }

    if (hasDescription) {
      _text(canvas, 'LA TRANSFORMATION', margin, y, w - 2 * margin,
        25, ink, bold: true);
      y += 36;
      _text(canvas, project.description, margin, y,
        w - 2 * margin, 23, muted, maxLines: 2);
    }

    canvas.drawRect(Rect.fromLTWH(margin, h - 80, w - margin * 2, 1.5),
      Paint()..color = accent.withValues(alpha: 0.25));
    _text(canvas, 'Avant / Après  ·  Application mobile', margin, h - 60,
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
