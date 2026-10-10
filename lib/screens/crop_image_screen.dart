import 'dart:io';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class CropImageScreen extends StatefulWidget {
  const CropImageScreen({
    super.key,
    required this.sourcePath,
    required this.title,
    this.aspectRatio = 16 / 9,
  });

  final String sourcePath;
  final String title;
  final double aspectRatio;

  @override
  State<CropImageScreen> createState() => _CropImageScreenState();
}

class _CropImageScreenState extends State<CropImageScreen> {
  final CropController _controller = CropController();

  Uint8List? _imageData;
  bool _isCropping = false;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await File(widget.sourcePath).readAsBytes();
      if (!mounted) return;

      setState(() {
        _imageData = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de charger l’image : $e')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<String> _writeTempCroppedFile(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/crop_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<void> _crop() async {
    if (_isCropping || !_isReady) return;

    setState(() {
      _isCropping = true;
    });

    _controller.crop();
  }

  Rect _buildAspectRatioRect(Rect viewportRect, double aspectRatio) {
    const horizontalMargin = 24.0;
    const verticalMargin = 24.0;

    final maxWidth = viewportRect.width - (horizontalMargin * 2);
    final maxHeight = viewportRect.height - (verticalMargin * 2);

    double cropWidth = maxWidth;
    double cropHeight = cropWidth / aspectRatio;

    if (cropHeight > maxHeight) {
      cropHeight = maxHeight;
      cropWidth = cropHeight * aspectRatio;
    }

    final left = viewportRect.left + (viewportRect.width - cropWidth) / 2;
    final top = viewportRect.top + (viewportRect.height - cropHeight) / 2;

    return Rect.fromLTWH(left, top, cropWidth, cropHeight);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _imageData == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Crop(
                        controller: _controller,
                        image: _imageData!,
                        onCropped: (result) async {
                          if (result is CropSuccess) {
                            try {
                              final path = await _writeTempCroppedFile(
                                result.croppedImage,
                              );
                              if (!mounted) return;
                              Navigator.of(context).pop(path);
                              return;
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Erreur pendant l’enregistrement : $e',
                                  ),
                                ),
                              );
                              setState(() {
                                _isCropping = false;
                              });
                              return;
                            }
                          }

                          if (result is CropFailure) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Erreur rognage : ${result.cause}',
                                ),
                              ),
                            );
                            setState(() {
                              _isCropping = false;
                            });
                          }
                        },
                        onStatusChanged: (status) {
                          final ready = status == CropStatus.ready;
                          if (ready != _isReady && mounted) {
                            setState(() {
                              _isReady = ready;
                            });
                          }
                        },
                        interactive: true,
                        fixCropRect: true,
                        withCircleUi: false,
                        radius: 20,
                        aspectRatio: widget.aspectRatio,
                        initialRectBuilder: InitialRectBuilder.withBuilder(
                          (viewportRect, imageRect) {
                            return _buildAspectRatioRect(
                              viewportRect,
                              widget.aspectRatio,
                            );
                          },
                        ),
                        maskColor: Colors.black.withValues(alpha: 0.45),
                        baseColor: colorScheme.surface,
                        cornerDotBuilder: (size, edgeAlignment) {
                          return Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          );
                        },
                        progressIndicator: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isCropping
                                ? null
                                : () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: (_isCropping || !_isReady) ? null : _crop,
                            icon: _isCropping
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.crop_rounded),
                            label: Text(_isCropping ? 'Rognage...' : 'Valider'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}