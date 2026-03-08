import 'dart:io';

import 'package:flutter/material.dart';

class BeforeAfterSlider extends StatefulWidget {
  const BeforeAfterSlider({
    super.key,
    required this.beforeImagePath,
    required this.afterImagePath,
    required this.sliderHeight,
    required this.showFrame,
    required this.frameColor,
  });

  final String beforeImagePath;
  final String afterImagePath;
  final double sliderHeight;
  final bool showFrame;
  final Color frameColor;

  @override
  State<BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<BeforeAfterSlider> {
  double _position = 0.5;

  @override
  Widget build(BuildContext context) {
    final beforeFile = File(widget.beforeImagePath);
    final afterFile = File(widget.afterImagePath);

    final hasBefore = widget.beforeImagePath.trim().isNotEmpty && beforeFile.existsSync();
    final hasAfter = widget.afterImagePath.trim().isNotEmpty && afterFile.existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: widget.sliderHeight,
        decoration: widget.showFrame
            ? BoxDecoration(
                border: Border.all(color: widget.frameColor, width: 2),
              )
            : null,
        child: !hasBefore
            ? _placeholder('broken image')
            : !hasAfter
                ? Image.file(
                    beforeFile,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder('broken image'),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final dividerX = constraints.maxWidth * _position;
                      return GestureDetector(
                        onHorizontalDragUpdate: (details) {
                          setState(() {
                            _position =
                                (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                          });
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              beforeFile,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholder('broken image'),
                            ),
                            ClipRect(
                              clipper: _AfterClipper(dividerX),
                              child: Image.file(
                                afterFile,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _placeholder('broken image'),
                              ),
                            ),
                            Positioned(
                              left: dividerX - 1,
                              top: 0,
                              bottom: 0,
                              child: Container(width: 2, color: Colors.white),
                            ),
                            Positioned(
                              left: dividerX - 16,
                              top: (widget.sliderHeight / 2) - 16,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black, width: 1.5),
                                ),
                                child: const Icon(Icons.drag_indicator, size: 18),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _placeholder(String text) {
    return Container(
      color: Colors.grey.shade300,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image_outlined),
            Text(text),
          ],
        ),
      ),
    );
  }
}

class _AfterClipper extends CustomClipper<Rect> {
  _AfterClipper(this.dividerX);

  final double dividerX;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, dividerX, size.height);

  @override
  bool shouldReclip(covariant _AfterClipper oldClipper) =>
      oldClipper.dividerX != dividerX;
}
