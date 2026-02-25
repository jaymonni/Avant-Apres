import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/photo_project.dart';
import '../providers/app_provider.dart';
import '../widgets/photo_card.dart';
import 'detail_screen.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key, required this.filter});

  final ProjectStatus filter;

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  bool _isGrid = true;

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final projects = appProvider.byStatus(widget.filter);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.filter == ProjectStatus.inProgress ? 'Projets en cours' : 'Mes projets'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _isGrid = !_isGrid),
            icon: Icon(_isGrid ? Icons.view_list_outlined : Icons.grid_view_rounded),
          ),
        ],
      ),
      body: projects.isEmpty
          ? const Center(child: Text('Aucun projet pour le moment.'))
          : _isGrid
              ? GridView.builder(
                  key: PageStorageKey<String>('grid_${widget.filter.name}'),
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return PhotoCard(
                      key: ValueKey<String>(project.id),
                      project: project,
                      onTap: () => _openDetail(project.id),
                    );
                  },
                )
              : ListView.builder(
                  key: PageStorageKey<String>('list_${widget.filter.name}'),
                  padding: const EdgeInsets.all(12),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return Card(
                      key: ValueKey<String>(project.id),
                      child: ListTile(
                        title: Text(project.title),
                        subtitle: Text(DateFormat('dd/MM/yyyy').format(project.createdAt)),
                        onTap: () => _openDetail(project.id),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDelete(project.id),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _confirmDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suppression'),
        content: const Text('Voulez-vous supprimer ce projet ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AppProvider>().deleteProject(id);
    }
  }

  void _openDetail(String id) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => DetailScreen(projectId: id)),
    );
  }
}
