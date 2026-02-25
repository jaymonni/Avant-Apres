import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/photo_project.dart';

class AppProvider extends ChangeNotifier {
  static const String storageKey = 'projects_v1';
  List<PhotoProject> _items = <PhotoProject>[];

  List<PhotoProject> get items => List<PhotoProject>.unmodifiable(_items);

  List<PhotoProject> byStatus(ProjectStatus status) {
    final filtered = _items.where((project) => project.status == status).toList();
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  PhotoProject? byId(String id) {
    for (final item in _items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) {
      _items = <PhotoProject>[];
      return;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      _items = <PhotoProject>[];
      return;
    }

    _items = decoded
        .whereType<Map>()
        .map((item) => PhotoProject.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_items.map((item) => item.toJson()).toList());
    await prefs.setString(storageKey, raw);
  }

  Future<void> addProject(PhotoProject project) async {
    _items.add(project);
    _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await save();
    notifyListeners();
  }

  Future<void> deleteProject(String id) async {
    _items.removeWhere((item) => item.id == id);
    await save();
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    final project = byId(id);
    if (project == null) return;

    project.isFavorite = !project.isFavorite;
    await save();
    notifyListeners();
  }

  Future<void> updateStatus(String id, ProjectStatus status) async {
    final project = byId(id);
    if (project == null) return;

    project.status = status;
    await save();
    notifyListeners();
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
      project.duringPath = duringPath;
    }

    project.afterNote = afterNote;
    project.duringNote = duringNote;

    if (project.afterPath.trim().isNotEmpty) {
      project.status = ProjectStatus.done;
    }

    await save();
    notifyListeners();
  }
}

class LocalProjectFiles {
  static String slug(String title) {
    final lower = title.toLowerCase();
    final onlyValid = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final collapsed = onlyValid.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
    final safe = collapsed.isEmpty ? 'project' : collapsed;
    return safe.length > 40 ? safe.substring(0, 40) : safe;
  }

  static Future<Directory> projectFolder(String id, String title) async {
    final docs = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(docs.path, 'projects', '${id}_${slug(title)}'));
    if (!folder.existsSync()) {
      await folder.create(recursive: true);
    }
    return folder;
  }

  static Future<String> copyXFileToProject(
    XFile xfile,
    Directory folder,
    String label,
  ) async {
    final dest = p.join(folder.path, '$label.jpg');
    final bytes = await xfile.readAsBytes();
    final file = File(dest);
    await file.writeAsBytes(bytes, flush: true);
    return dest;
  }
}
