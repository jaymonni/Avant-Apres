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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Aperçu indisponible : $e')));
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur de partage : $e')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.project;
    return Scaffold(
      appBar: AppBar(title: const Text('Personnaliser le partage')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: FilledButton.icon(
          onPressed: busy || previewPath == null ? null : _share,
          icon: const Icon(Icons.share),
          label: const Text('Partager cette transformation'),
        ),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Aperçu du partage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (previewPath != null)
          Center(child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: Image.file(File(previewPath!), key: ValueKey(previewPath), fit: BoxFit.contain),
          )),
        if (busy) const LinearProgressIndicator(),
        const SizedBox(height: 18),
        const Text('Couleur', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final choice in ShareAccent.values)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Tooltip(
                  message: switch (choice) {
                    ShareAccent.sage => 'Sauge',
                    ShareAccent.terracotta => 'Terracotta',
                    ShareAccent.blue => 'Bleu doux',
                    ShareAccent.lavender => 'Lavande',
                    ShareAccent.sand => 'Sable',
                    ShareAccent.charcoal => 'Anthracite',
                  },
                  child: Semantics(
                    label: 'Couleur : ${choice.name}',
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
        const Text('Format', style: TextStyle(fontWeight: FontWeight.bold)),
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
          SwitchListTile(title: const Text('Note Avant'), value: beforeNote,
            onChanged: (v) => _change(() => beforeNote = v)),
        if (p.afterNote.trim().isNotEmpty)
          SwitchListTile(title: const Text('Note Après'), value: afterNote,
            onChanged: (v) => _change(() => afterNote = v)),
        if (p.description.trim().isNotEmpty)
          SwitchListTile(title: const Text('Description générale'), value: description,
            onChanged: (v) => _change(() => description = v)),
        if (p.duringPhotos.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Text('Choisir les photos Pendant', style: TextStyle(fontWeight: FontWeight.bold)),
          ...p.duringPhotos.map((photo) => CheckboxListTile(
            secondary: File(photo.path).existsSync()
              ? Image.file(File(photo.path), width: 48, height: 48, fit: BoxFit.cover)
              : const Icon(Icons.broken_image),
            title: Text(photo.note.trim().isEmpty ? 'Étape Pendant' : photo.note,
              maxLines: 2, overflow: TextOverflow.ellipsis),
            value: selected.contains(photo.id),
            onChanged: (v) => _change(() {
              if (v == true) { selected.add(photo.id); } else { selected.remove(photo.id); }
            }),
          )),
          SwitchListTile(title: const Text('Notes des photos Pendant'),
            value: duringNotes, onChanged: (v) => _change(() => duringNotes = v)),
        ],
        const SizedBox(height: 16),
      ]),
    );
  }
}
