import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/photo_project.dart';
import '../providers/app_provider.dart';
import '../widgets/photo_card.dart';
import 'detail_screen.dart';

enum ProjectStatusFilter { inProgress, done }

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key, required this.filter});

  final ProjectStatusFilter filter;

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  bool _isGrid = true;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final provider = context.watch<AppProvider>();
    final DateFormat formatter = DateFormat('dd/MM/yyyy');

    final items = widget.filter == ProjectStatusFilter.inProgress
        ? provider.inProgressItems
        : provider.doneItems;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.filter == ProjectStatusFilter.inProgress
              ? strings.t('inProgress')
              : strings.t('done'),
        ),
        actions: [
          IconButton(
            tooltip: _isGrid ? strings.t('list') : strings.t('grid'),
            onPressed: () => setState(() => _isGrid = !_isGrid),
            icon: Icon(_isGrid ? Icons.view_list : Icons.grid_view),
          ),
        ],
      ),
      body: items.isEmpty
          ? const Center(child: Text('Aucun projet'))
          : _isGrid
              ? GridView.builder(
                  key: PageStorageKey('grid_${widget.filter.name}'),
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.78,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final project = items[index];
                    return PhotoCard(
                      key: ValueKey(project.id),
                      project: project,
                      onTap: () => _open(project.id),
                      onDelete: () => _confirmDelete(project.id),
                    );
                  },
                )
              : ListView.builder(
                  key: PageStorageKey('list_${widget.filter.name}'),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final project = items[index];
                    return ListTile(
                      key: ValueKey(project.id),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: Image.file(
                            File(project.beforePath),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                      ),
                      title: Text(project.title),
                      subtitle: Text(formatter.format(project.createdAt)),
                      onTap: () => _open(project.id),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDelete(project.id),
                      ),
                    );
                  },
                ),
    );
  }

  void _open(String id) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailScreen(projectId: id)),
    );
  }

  Future<void> _confirmDelete(String id) async {
    final strings = AppStrings.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(strings.t('deleteConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(strings.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(strings.t('delete')),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      await context.read<AppProvider>().deleteProject(id);
    }
  }
}
