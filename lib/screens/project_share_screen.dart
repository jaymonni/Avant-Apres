import 'dart:io';
import 'package:flutter/material.dart';
import '../models/photo_project.dart';
import '../services/share_project_service.dart';
import '../services/express_ads_service.dart';

class ProjectShareScreen extends StatefulWidget {
  const ProjectShareScreen({super.key, required this.project, required this.shareText});
  final PhotoProject project;
  final String shareText;

  @override
  State<ProjectShareScreen> createState() => _ProjectShareScreenState();
}

class _ProjectShareScreenState extends State<ProjectShareScreen> {
  String _tr(String fr, String en, String es, String pt) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'fr': return fr;
      case 'es': return es;
      case 'pt': return pt;
      default: return en;
    }
  }

  ShareAccent accent = ShareAccent.sage;
  ShareFormat format = ShareFormat.portrait;
  bool beforeNote = true, afterNote = true, description = true, duringNotes = true;
  final Set<String> selected = {};
  String? previewPath;
  bool busy = false;
  int generation = 0;

  ProjectShareOptions get options => ProjectShareOptions(
    accent: accent, format: format, beforeNote: beforeNote, afterNote: afterNote,
    description: description, duringNotes: duringNotes,
    duringIds: Set.of(selected),
  );

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final token = ++generation;
    setState(() { busy = true; });
    try {
      final path = await ShareProjectService.buildShareImage(widget.project, options);
      if (!mounted || token != generation) return;
      setState(() { previewPath = path; busy = false; });
    } catch (e) {
      if (!mounted || token != generation) return;
      setState(() { busy = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_tr('Aperçu indisponible : $e', 'Preview unavailable: $e', 'Vista previa no disponible: $e', 'Pré-visualização indisponível: $e'))));
    }
  }

  void _change(VoidCallback action) {
    setState(action);
    _refresh();
  }

  Future<void> _share() async {
    if (busy || previewPath == null) return;
    setState(() => busy = true);
    try {
      await ShareProjectService.shareFinishedProject(widget.project,
        shareText: widget.shareText, options: options);
      ExpressAdsService().onCompletedAction();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_tr('Erreur de partage : $e', 'Sharing error: $e', 'Error al compartir: $e', 'Erro ao partilhar: $e'))));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.project;
    return Scaffold(
      appBar: AppBar(title: Text(_tr('Personnaliser le partage', 'Customize sharing', 'Personalizar el uso compartido', 'Personalizar a partilha'))),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: FilledButton.icon(
          onPressed: busy || previewPath == null ? null : _share,
          icon: const Icon(Icons.share),
          label: Text(_tr('Partager cette transformation', 'Share this transformation', 'Compartir esta transformación', 'Partilhar esta transformação')),
        ),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(_tr('Aperçu du partage', 'Share preview', 'Vista previa', 'Pré-visualização da partilha'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (previewPath != null)
          Center(child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: Image.file(File(previewPath!), key: ValueKey(previewPath), fit: BoxFit.contain),
          )),
        if (busy) const LinearProgressIndicator(),
        const SizedBox(height: 18),
        Text(_tr('Couleur', 'Color', 'Color', 'Cor'), style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final choice in ShareAccent.values)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Tooltip(
                  message: switch (choice) {
                    ShareAccent.sage => _tr('Sauge', 'Sage', 'Salvia', 'Sálvia'),
                    ShareAccent.terracotta => _tr('Terracotta', 'Terracotta', 'Terracota', 'Terracota'),
                    ShareAccent.blue => _tr('Bleu doux', 'Soft blue', 'Azul suave', 'Azul suave'),
                    ShareAccent.lavender => _tr('Lavande', 'Lavender', 'Lavanda', 'Lavanda'),
                    ShareAccent.sand => _tr('Sable', 'Sand', 'Arena', 'Areia'),
                    ShareAccent.charcoal => _tr('Anthracite', 'Charcoal', 'Antracita', 'Antracite'),
                  },
                  child: Semantics(
                    label: '${_tr('Couleur', 'Color', 'Color', 'Cor')} : ${choice.name}',
                    selected: accent == choice,
                    child: InkWell(
                      onTap: () => _change(() => accent = choice),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 46, height: 46,
                        decoration: BoxDecoration(
                          color: choice.color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accent == choice ? Colors.black87 : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: accent == choice
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                      ),
                    ),
                  ),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 16),
        Text(_tr('Format', 'Format', 'Formato', 'Formato'), style: TextStyle(fontWeight: FontWeight.bold)),
        SegmentedButton<ShareFormat>(
          segments: const [
            ButtonSegment(value: ShareFormat.square, label: Text('1:1')),
            ButtonSegment(value: ShareFormat.portrait, label: Text('4:5')),
            ButtonSegment(value: ShareFormat.story, label: Text('9:16')),
          ],
          selected: {format}, onSelectionChanged: (s) => _change(() => format = s.first),
        ),
        const Divider(height: 32),
        if (p.beforeNote.trim().isNotEmpty)
          SwitchListTile(title: Text(_tr('Note Avant', 'Before note', 'Nota Antes', 'Nota Antes')), value: beforeNote,
            onChanged: (v) => _change(() => beforeNote = v)),
        if (p.afterNote.trim().isNotEmpty)
          SwitchListTile(title: Text(_tr('Note Après', 'After note', 'Nota Después', 'Nota Depois')), value: afterNote,
            onChanged: (v) => _change(() => afterNote = v)),
        if (p.description.trim().isNotEmpty)
          SwitchListTile(title: Text(_tr('Description générale', 'General description', 'Descripción general', 'Descrição geral')), value: description,
            onChanged: (v) => _change(() => description = v)),
        if (p.duringPhotos.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(_tr('Choisir les photos Pendant', 'Select during photos', 'Elegir fotos intermedias', 'Escolher fotos intermédias'), style: TextStyle(fontWeight: FontWeight.bold)),
          ...p.duringPhotos.map((photo) => CheckboxListTile(
            secondary: File(photo.path).existsSync()
              ? Image.file(File(photo.path), width: 48, height: 48, fit: BoxFit.cover)
              : const Icon(Icons.broken_image),
            title: Text(photo.note.trim().isEmpty ? _tr('Étape Pendant', 'During step', 'Etapa intermedia', 'Etapa intermédia') : photo.note,
              maxLines: 2, overflow: TextOverflow.ellipsis),
            value: selected.contains(photo.id),
            onChanged: (v) => _change(() {
              if (v == true) { selected.add(photo.id); } else { selected.remove(photo.id); }
            }),
          )),
          SwitchListTile(title: Text(_tr('Notes des photos Pendant', 'During photo notes', 'Notas de fotos intermedias', 'Notas das fotos intermédias')),
            value: duringNotes, onChanged: (v) => _change(() => duringNotes = v)),
        ],
        const SizedBox(height: 16),
      ]),
    );
  }
}
