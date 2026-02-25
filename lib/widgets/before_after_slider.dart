import 'dart:io';

import 'package:flutter/material.dart';

class BeforeAfterSlider extends StatefulWidget {
  const BeforeAfterSlider({
    super.key,
    required this.beforeImagePath,
    required this.afterImagePath,
    this.sliderHeight = 250,
    this.showFrame = true,
    this.frameColor,
  });

  final String beforeImagePath;
  final String afterImagePath;
  final double sliderHeight;
  final bool showFrame;
  final Color? frameColor;

  @override
  State<BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<BeforeAfterSlider> {
  double _positionFactor = 0.5;

  bool get _hasAfter => widget.afterImagePath.trim().isNotEmpty && File(widget.afterImagePath).existsSync();

  @override
  Widget build(BuildContext context) {
    final border = widget.showFrame
        ? Border.all(
            color: widget.frameColor ?? Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
            width: 1.5,
          )
        : null;

    if (!_hasAfter) {
      return Container(
        height: widget.sliderHeight,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: border),
        clipBehavior: Clip.antiAlias,
        child: Image.file(
          File(widget.beforeImagePath),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const _BrokenImage(),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final handleX = width * _positionFactor;

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            final localX = details.localPosition.dx.clamp(0, width);
            setState(() => _positionFactor = localX / width);
          },
          onTapDown: (details) {
            final localX = details.localPosition.dx.clamp(0, width);
            setState(() => _positionFactor = localX / width);
          },
          child: Container(
            height: widget.sliderHeight,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: border),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  File(widget.beforeImagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const _BrokenImage(),
                ),
                ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: _positionFactor,
                    child: Image.file(
                      File(widget.afterImagePath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _BrokenImage(),
                    ),
                  ),
                ),
                Positioned(
                  left: handleX - 1,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 2, color: Colors.white),
                ),
                Positioned(
                  left: handleX - 16,
                  top: (widget.sliderHeight / 2) - 16,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.drag_handle, size: 20),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BrokenImage extends StatelessWidget {
  const _BrokenImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: const Text('broken image'),
    );
  }
}
