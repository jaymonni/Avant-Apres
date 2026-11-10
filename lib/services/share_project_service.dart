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
    const gap = 8.0;
    const footerTopGap = 12.0;
    const footerHeight = 70.0;
    const titleTop = 36.0;
    const titleArea = 105.0;
    const labelHeight = 0.0;
    const sectionGap = 16.0;
    const framePadding = 4.0;
    final hasNotes = (options.beforeNote && project.beforeNote.trim().isNotEmpty) ||
      (options.afterNote && project.afterNote.trim().isNotEmpty);
    final hasDescription = options.description && project.description.trim().isNotEmpty;
    final noteHeight = hasNotes ? 76.0 : 0.0;
    final descHeight = hasDescription ? 100.0 : 0.0;
    final stepsHeight = steps.isEmpty ? 0.0 :
      (options.format == ShareFormat.square ? 255.0 :
        options.format == ShareFormat.portrait ? 310.0 : 420.0);
    final photoBudget = h - titleTop - titleArea - labelHeight - framePadding * 2 -
      noteHeight - descHeight - stepsHeight - footerHeight -
      footerTopGap - sectionGap - 12;
    final photoHeight = photoBudget.clamp(240.0, 1100.0).toDouble();

    _centeredTitle(canvas, project.title.trim().isEmpty ? 'Avant / Après' : project.title,
      Rect.fromLTWH(margin, titleTop, w - margin * 2, titleArea), accent);
    double y = titleTop + titleArea;

    final frame = RRect.fromRectAndRadius(
      Rect.fromLTWH(margin, y, w - 2 * margin, photoHeight + framePadding * 2),
      const Radius.circular(14));
    canvas.drawRRect(frame, Paint()..color = accent);
    final innerWidth = (w - 2 * margin - framePadding * 2 - gap) / 2;
    for (var i = 0; i < 2; i++) {
      final x = margin + framePadding + i * (innerWidth + gap);
      final image = await _load(i == 0 ? project.beforePath : project.afterPath);
      final photoRect = Rect.fromLTWH(x, y + framePadding, innerWidth, photoHeight);
      _cover(canvas, image, photoRect, 10);
      final label = i == 0 ? 'AVANT' : 'APRÈS';
      final labelWidth = label == 'AVANT' ? 88.0 : 92.0;
      final labelRect = Rect.fromLTWH(
        x + 10, y + framePadding + photoHeight - 42, labelWidth, 32);
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(8)),
        Paint()..color = const Color(0xB8222222));
      _text(canvas, label, labelRect.left + 5, labelRect.top + 5,
        labelRect.width - 10, 18, Colors.white, bold: true,
        align: TextAlign.center);
      final note = i == 0 ? project.beforeNote : project.afterNote;
      if (hasNotes && (i == 0 ? options.beforeNote : options.afterNote) &&
          note.trim().isNotEmpty) {
        _text(canvas, note, x + 5, y + photoHeight + framePadding * 2 + 12,
          innerWidth - 10, 28, muted, maxLines: 2);
      }
    }
    y += photoHeight + framePadding * 2 + noteHeight + sectionGap;

    if (steps.isNotEmpty) {
      _text(canvas, 'LES ÉTAPES', margin, y, w - margin * 2, 26,
        ink, bold: true);
      y += 34;
      final columns = steps.length == 1 ? 1 : 2;
      final rows = (steps.length / columns).ceil();
      final cellW = steps.length == 1 ? 520.0 : (w - margin * 2 - gap) / 2;
      final rowH = (stepsHeight - 40) / rows;
      for (var i = 0; i < steps.length; i++) {
        final row = i ~/ columns;
        final column = i % columns;
        final x = steps.length == 1
          ? (w - cellW) / 2
          : margin + column * (cellW + gap);
        final top = y + row * rowH;
        final hasStepNote = options.duringNotes && steps[i].note.trim().isNotEmpty;
        final noteH = hasStepNote && rowH >= 95 ? 37.0 : 0.0;
        final imgH = (rowH - noteH - 12).clamp(24.0, rowH).toDouble();
        final image = await _load(steps[i].path);
        _contain(canvas, image, Rect.fromLTWH(x, top, cellW, imgH), 12);
        if (noteH > 0) {
          _text(canvas, steps[i].note, x + 4, top + imgH + 4,
            cellW - 8, 25, muted, maxLines: 1);
        }
      }
      y += stepsHeight - 34;
    }

    if (hasDescription) {
      _text(canvas, 'LA TRANSFORMATION', margin, y, w - 2 * margin,
        25, ink, bold: true);
      y += 36;
      _text(canvas, project.description, margin, y,
        w - 2 * margin, 27, muted, maxLines: 2);
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

  static void _contain(Canvas canvas, ui.Image image, Rect dest, double radius) {
    final scale = (dest.width / image.width < dest.height / image.height)
      ? dest.width / image.width : dest.height / image.height;
    final fittedW = image.width * scale;
    final fittedH = image.height * scale;
    final fitted = Rect.fromLTWH(
      dest.left + (dest.width - fittedW) / 2,
      dest.top + (dest.height - fittedH) / 2,
      fittedW, fittedH);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(dest, Radius.circular(radius)));
    canvas.clipRRect(RRect.fromRectAndRadius(fitted, Radius.circular(radius)));
    canvas.drawImageRect(image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      fitted, Paint()..filterQuality = FilterQuality.high);
    canvas.restore();
    image.dispose();
  }

  static void _centeredTitle(Canvas canvas, String title, Rect area, Color ink) {
    final painter = TextPainter(
      text: TextSpan(text: title, style: TextStyle(
        fontSize: 52, color: ink, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic, height: 1.18)),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: area.width);
    painter.paint(canvas, Offset(
      area.left + (area.width - painter.width) / 2,
      area.top + (area.height - painter.height) / 2));
    painter.dispose();
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
