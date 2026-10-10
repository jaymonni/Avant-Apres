import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/photo_project.dart';

class ShareProjectService {
  static Future<void> shareFinishedProject(
    PhotoProject project, {
    required String shareText,
  }) async {
    final beforeFile = File(project.beforePath);
    final afterFile = File(project.afterPath);

    if (!beforeFile.existsSync() || !afterFile.existsSync()) {
      throw Exception('Fichiers image introuvables');
    }

    final outputPath = await _buildShareImage(project);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(outputPath)],
        text: shareText,
        subject: project.title,
      ),
    );
  }

  static Future<String> _buildShareImage(PhotoProject project) async {
    const double canvasWidth = 1200;
    const double canvasHeight = 1500;

    const double outerPadding = 48;
    const double topAreaHeight = 180;
    const double gap = 28;
    const double labelHeight = 56;
    const double footerHeight = 70;
    const double imageRadius = 28;
    const double cardRadius = 36;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      const Rect.fromLTWH(0, 0, canvasWidth, canvasHeight),
    );

    final backgroundPaint = Paint()..color = const Color(0xFFF6F7F9);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, canvasWidth, canvasHeight),
      backgroundPaint,
    );

    final cardPaint = Paint()..color = Colors.white;
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.05);

    final contentTop = topAreaHeight;
    final contentHeight =
        canvasHeight - contentTop - footerHeight - outerPadding;
    final imageTop = contentTop + labelHeight + 18;
    final imageHeight = contentHeight - labelHeight - 18;

    final panelWidth = (canvasWidth - outerPadding * 2 - gap) / 2;

    final beforeCardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        outerPadding,
        contentTop,
        panelWidth,
        contentHeight,
      ),
      const Radius.circular(cardRadius),
    );

    final afterCardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        outerPadding + panelWidth + gap,
        contentTop,
        panelWidth,
        contentHeight,
      ),
      const Radius.circular(cardRadius),
    );

    canvas.drawRRect(beforeCardRect.shift(const Offset(0, 8)), shadowPaint);
    canvas.drawRRect(afterCardRect.shift(const Offset(0, 8)), shadowPaint);

    canvas.drawRRect(beforeCardRect, cardPaint);
    canvas.drawRRect(afterCardRect, cardPaint);

    final beforeImage = await _loadUiImage(project.beforePath);
    final afterImage = await _loadUiImage(project.afterPath);

    final beforeImageRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        outerPadding + 16,
        imageTop,
        panelWidth - 32,
        imageHeight - 16,
      ),
      const Radius.circular(imageRadius),
    );

    final afterImageRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        outerPadding + panelWidth + gap + 16,
        imageTop,
        panelWidth - 32,
        imageHeight - 16,
      ),
      const Radius.circular(imageRadius),
    );

    _drawCoverImage(canvas, beforeImage, beforeImageRect.outerRect);
    _drawCoverImage(canvas, afterImage, afterImageRect.outerRect);

    _drawImageMask(canvas, beforeImageRect);
    _drawImageMask(canvas, afterImageRect);

    _drawTitle(
      canvas,
      text: project.title.trim().isEmpty ? 'Avant / Après' : project.title.trim(),
      width: canvasWidth,
      top: 56,
    );

    _drawPill(
      canvas,
      rect: Rect.fromLTWH(
        outerPadding + 16,
        contentTop + 16,
        140,
        42,
      ),
      text: 'AVANT',
      background: const Color(0xFFEAF2FF),
      foreground: const Color(0xFF2457D6),
    );

    _drawPill(
      canvas,
      rect: Rect.fromLTWH(
        outerPadding + panelWidth + gap + 16,
        contentTop + 16,
        140,
        42,
      ),
      text: 'APRÈS',
      background: const Color(0xFFE8FAEF),
      foreground: const Color(0xFF1E8E4A),
    );

    _drawFooter(
      canvas,
      text: 'Créé avec Avant / Après',
      width: canvasWidth,
      top: canvasHeight - footerHeight,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      canvasWidth.toInt(),
      canvasHeight.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Impossible de générer l’image de partage');
    }

    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/share_${project.id}_${DateTime.now().millisecondsSinceEpoch}.png',
    );

    await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    return file.path;
  }

  static Future<ui.Image> _loadUiImage(String path) async {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  static void _drawCoverImage(Canvas canvas, ui.Image image, Rect dstRect) {
    final srcWidth = image.width.toDouble();
    final srcHeight = image.height.toDouble();

    final srcRatio = srcWidth / srcHeight;
    final dstRatio = dstRect.width / dstRect.height;

    Rect srcRect;

    if (srcRatio > dstRatio) {
      final newWidth = srcHeight * dstRatio;
      final left = (srcWidth - newWidth) / 2;
      srcRect = Rect.fromLTWH(left, 0, newWidth, srcHeight);
    } else {
      final newHeight = srcWidth / dstRatio;
      final top = (srcHeight - newHeight) / 2;
      srcRect = Rect.fromLTWH(0, top, srcWidth, newHeight);
    }

    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(dstRect, const Radius.circular(28)),
    );
    canvas.drawImageRect(image, srcRect, dstRect, Paint());
    canvas.restore();
  }

  static void _drawImageMask(Canvas canvas, RRect rect) {
    final borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(rect, borderPaint);
  }

  static void _drawTitle(
    Canvas canvas, {
    required String text,
    required double width,
    required double top,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF111827),
          fontSize: 42,
          fontWeight: FontWeight.w800,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    );

    painter.layout(maxWidth: width - 120);

    painter.paint(
      canvas,
      Offset((width - painter.width) / 2, top),
    );
  }

  static void _drawFooter(
    Canvas canvas, {
    required String text,
    required double width,
    required double top,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.black.withValues(alpha: 0.45),
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    );

    painter.layout(maxWidth: width - 120);

    painter.paint(
      canvas,
      Offset((width - painter.width) / 2, top + 12),
    );
  }

  static void _drawPill(
    Canvas canvas, {
    required Rect rect,
    required String text,
    required Color background,
    required Color foreground,
  }) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(999));

    final paint = Paint()..color = background;
    canvas.drawRRect(rrect, paint);

    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: foreground,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );

    painter.layout(maxWidth: rect.width - 24);
    painter.paint(
      canvas,
      Offset(
        rect.left + (rect.width - painter.width) / 2,
        rect.top + (rect.height - painter.height) / 2,
      ),
    );
  }
}