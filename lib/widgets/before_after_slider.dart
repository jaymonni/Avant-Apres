import 'dart:io';

import 'package:flutter/material.dart';

class BeforeAfterSlider extends StatefulWidget {
  const BeforeAfterSlider({
    super.key,
    required this.beforeImagePath,
    required this.afterImagePath,
    this.sliderHeight = 280,
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
  double _position = 0.5;

  bool _exists(String path) {
    return path.trim().isNotEmpty && File(path).existsSync();
  }

  void _updatePosition(double dx, double width) {
    if (width <= 0) return;

    setState(() {
      _position = (dx / width).clamp(0.0, 1.0);
    });
  }

  Widget _placeholder(BuildContext context, String text) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.onSurface.withValues(alpha: 0.05),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.55),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildImage(String path, String fallback) {
    final file = File(path);

    if (!file.existsSync()) {
      return _placeholder(context, fallback);
    }

    return Image.file(
      file,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return _placeholder(context, fallback);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final beforeExists = _exists(widget.beforeImagePath);
    final afterExists = _exists(widget.afterImagePath);

    final frameColor = widget.frameColor ??
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.16);

    if (!beforeExists && !afterExists) {
      return SizedBox(
        height: widget.sliderHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: _placeholder(context, 'Images indisponibles'),
        ),
      );
    }

    if (!afterExists) {
      return Container(
        height: widget.sliderHeight,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: widget.showFrame
              ? Border.all(color: frameColor, width: 1.2)
              : null,
        ),
        child: _buildImage(widget.beforeImagePath, 'Image avant indisponible'),
      );
    }

    if (!beforeExists) {
      return Container(
        height: widget.sliderHeight,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: widget.showFrame
              ? Border.all(color: frameColor, width: 1.2)
              : null,
        ),
        child: _buildImage(widget.afterImagePath, 'Image après indisponible'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final dividerX = width * _position;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _updatePosition(details.localPosition.dx, width),
          onHorizontalDragUpdate: (details) =>
              _updatePosition(details.localPosition.dx, width),
          child: Container(
            height: widget.sliderHeight,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: widget.showFrame
                  ? Border.all(color: frameColor, width: 1.2)
                  : null,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: _buildImage(
                    widget.beforeImagePath,
                    'Image avant indisponible',
                  ),
                ),
                Positioned.fill(
                  child: ClipPath(
                    clipper: _LeftRevealClipper(_position),
                    child: _buildImage(
                      widget.afterImagePath,
                      'Image après indisponible',
                    ),
                  ),
                ),
                Positioned(
                  left: dividerX - 1,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 2,
                    color: Colors.white,
                  ),
                ),
                Positioned(
                  left: dividerX - 18,
                  top: (widget.sliderHeight / 2) - 18,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.drag_indicator_rounded,
                      size: 20,
                      color: Colors.black87,
                    ),
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

class _LeftRevealClipper extends CustomClipper<Path> {
  const _LeftRevealClipper(this.position);

  final double position;

  @override
  Path getClip(Size size) {
    final revealWidth = size.width * position;
    return Path()
      ..addRect(
        Rect.fromLTWH(0, 0, revealWidth, size.height),
      );
  }

  @override
  bool shouldReclip(covariant _LeftRevealClipper oldClipper) {
    return oldClipper.position != position;
  }
}