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
  late double _selectedAspectRatio = widget.aspectRatio;
  int _cropRevision = 0;

  void _selectRatio(double ratio) {
    if (_isCropping || ratio == _selectedAspectRatio) return;
    setState(() {
      _selectedAspectRatio = ratio;
      _isReady = false;
      _cropRevision++;
    });
  }

  void _resetCrop() {
    if (_isCropping) return;
    setState(() {
      _isReady = false;
      _cropRevision++;
    });
  }

  String _tr(String fr, String en, String es, String pt) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'fr': return fr;
      case 'es': return es;
      case 'pt': return pt;
      default: return en;
    }
  }

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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_tr('Format du cadre', 'Frame format', 'Formato del marco', 'Formato do quadro'),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          for (final ratio in <double>[16 / 9, 4 / 5, 1, 3 / 4]) ...[
                            ChoiceChip(
                              label: Text(ratio == 16 / 9 ? '16:9' : ratio == 4 / 5 ? '4:5' : ratio == 1 ? '1:1' : '3:4'),
                              selected: (_selectedAspectRatio - ratio).abs() < 0.001,
                              onSelected: (_) => _selectRatio(ratio),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ]),
                      ),
                      const SizedBox(height: 8),
                      Text(_tr('Déplacez et zoomez la photo avec deux doigts pour ajuster le cadrage.',
                          'Move and pinch the photo to adjust the framing.',
                          'Mueve y amplía la foto con dos dedos para ajustar el encuadre.',
                          'Mova e amplie a foto com dois dedos para ajustar o enquadramento.'),
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.72))),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Crop(
                        key: ValueKey('crop_$_cropRevision'),
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
                        aspectRatio: _selectedAspectRatio,
                        initialRectBuilder: InitialRectBuilder.withBuilder(
                          (viewportRect, imageRect) {
                            return _buildAspectRatioRect(
                              viewportRect,
                              _selectedAspectRatio,
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
                        IconButton(
                          onPressed: _isCropping ? null : _resetCrop,
                          tooltip: _tr('Réinitialiser le cadrage', 'Reset crop', 'Restablecer recorte', 'Redefinir recorte'),
                          icon: const Icon(Icons.restart_alt_rounded),
                        ),
                        const SizedBox(width: 6),
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