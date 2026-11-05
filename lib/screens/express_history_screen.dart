import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/express_history_service.dart';

class ExpressHistoryScreen extends StatefulWidget {
  const ExpressHistoryScreen({super.key});

  @override
  State<ExpressHistoryScreen> createState() => _ExpressHistoryScreenState();
}

class _ExpressHistoryScreenState extends State<ExpressHistoryScreen> {
  late Future<List<ExpressHistoryItem>> _items;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _items = ExpressHistoryService.load();
  }

  String _tr(String fr, String en, String es, String pt) =>
      switch (Localizations.localeOf(context).languageCode) {
        'en' => en, 'es' => es, 'pt' => pt, _ => fr,
      };

  Future<void> _delete(ExpressHistoryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_tr('Supprimer cette image ?', 'Delete this image?',
            '¿Eliminar esta imagen?', 'Eliminar esta imagem?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text(_tr('Annuler', 'Cancel', 'Cancelar', 'Cancelar'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: Text(_tr('Supprimer', 'Delete', 'Eliminar', 'Eliminar'))),
        ],
      ),
    );
    if (confirmed != true) return;
    await ExpressHistoryService.delete(item);
    if (mounted) setState(_refresh);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_tr('Historique Express', 'Express history',
        'Historial exprés', 'Histórico Express'))),
    body: FutureBuilder<List<ExpressHistoryItem>>(
      future: _items,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data!;
        if (items.isEmpty) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_tr('Tes prochaines images enregistrées apparaîtront ici.',
                'Your next saved images will appear here.',
                'Tus próximas imágenes guardadas aparecerán aquí.',
                'As próximas imagens guardadas aparecerão aqui.'),
                textAlign: TextAlign.center),
          ));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
            childAspectRatio: .7,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(clipBehavior: Clip.antiAlias,
              child: Column(children: [
                Expanded(child: InkWell(
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (ctx) => Dialog.fullscreen(child: Scaffold(
                      appBar: AppBar(title: Text(_tr('Aperçu', 'Preview',
                          'Vista previa', 'Pré-visualização'))),
                      body: InteractiveViewer(child: Center(
                        child: Image.file(File(item.path), fit: BoxFit.contain),
                      )),
                    )),
                  ),
                  child: SizedBox.expand(child: Image.file(
                    File(item.path), fit: BoxFit.cover,
                  )),
                )),
                Row(children: [
                  Expanded(child: IconButton(
                    tooltip: _tr('Partager', 'Share', 'Compartir', 'Partilhar'),
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () => SharePlus.instance.share(
                      ShareParams(files: [XFile(item.path)])),
                  )),
                  Expanded(child: IconButton(
                    tooltip: _tr('Supprimer', 'Delete', 'Eliminar', 'Eliminar'),
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(item),
                  )),
                ]),
              ]),
            );
          },
        );
      },
    ),
  );
}
