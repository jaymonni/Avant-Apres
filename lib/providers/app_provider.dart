import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/photo_project.dart';

class AppProvider extends ChangeNotifier {
  static const String _storageKey = 'projects_v1';

  List<PhotoProject> _items = [];

  List<PhotoProject> get items => List.unmodifiable(_items);

  List<PhotoProject> get inProgressItems => _items
      .where((p) => p.status == ProjectStatus.inProgress)
      .toList(growable: false);

  List<PhotoProject> get doneItems =>
      _items.where((p) => p.status == ProjectStatus.done).toList(growable: false);

  PhotoProject? byId(String id) {
    try {
      return _items.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      _items = [];
      notifyListeners();
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _items = decoded
            .whereType<Map>()
            .map((e) => PhotoProject.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        _items = [];
      }
    } catch (_) {
      _items = [];
    }

    _sort();
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_items.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> addProject(PhotoProject project) async {
    _items.add(project);
    _sort();
    notifyListeners();
    await save();
  }

  Future<void> deleteProject(String id) async {
    final project = byId(id);
    if (project != null) {
      final folder = await projectFolder(project.id, project.title);
      if (await folder.exists()) {
        await folder.delete(recursive: true);
      }
    }
    _items.removeWhere((p) => p.id == id);
    notifyListeners();
    await save();
  }

  Future<void> toggleFavorite(String id) async {
    final project = byId(id);
    if (project == null) return;
    project.isFavorite = !project.isFavorite;
    notifyListeners();
    await save();
  }

  Future<void> updateStatus(String id, ProjectStatus status) async {
    final project = byId(id);
    if (project == null) return;
    project.status = status;
    notifyListeners();
    await save();
  }

  Future<void> updateProjectNotesAndPhotos(
    String id, {
    String? afterPath,
    String? duringPath,
    required String afterNote,
    required String duringNote,
  }) async {
    final project = byId(id);
    if (project == null) return;

    if (afterPath != null) {
      project.afterPath = afterPath;
    }
    if (duringPath != null) {
      project.duringPath = duringPath.trim().isEmpty ? null : duringPath;
    }
    project.afterNote = afterNote;
    project.duringNote = duringNote;

    if (project.afterPath.trim().isNotEmpty) {
      project.status = ProjectStatus.done;
    }

    _sort();
    notifyListeners();
    await save();
  }

  void _sort() {
    _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  String slug(String title) {
    final lower = title.toLowerCase();
    final replaced = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final single = replaced.replaceAll(RegExp(r'_+'), '_');
    final trimmed = single.replaceAll(RegExp(r'^_+|_+$'), '');
    final fallback = trimmed.isEmpty ? 'project' : trimmed;
    return fallback.length <= 40 ? fallback : fallback.substring(0, 40);
  }

  Future<Directory> projectFolder(String id, String title) async {
    final docs = await getApplicationDocumentsDirectory();
    final projectsDir = Directory('${docs.path}/projects');
    if (!await projectsDir.exists()) {
      await projectsDir.create(recursive: true);
    }
    final folder = Directory('${projectsDir.path}/${id}_${slug(title)}');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return folder;
  }

  Future<String> copyXFileToProject(
    Directory folder,
    XFile xfile,
    String label,
  ) async {
    final bytes = await xfile.readAsBytes();
    final destination = File('${folder.path}/$label.jpg');
    await destination.writeAsBytes(bytes, flush: true);
    return destination.path;
  }
}
