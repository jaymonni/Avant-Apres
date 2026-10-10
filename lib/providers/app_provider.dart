import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/photo_project.dart';

class AppProvider extends ChangeNotifier {
  static const String _prefsKey = 'projects_v1';

  final List<PhotoProject> _items = [];

  List<PhotoProject> get items => List.unmodifiable(_items);

  List<PhotoProject> filtered(ProjectStatus status) {
    return _items.where((item) => item.status == status).toList();
  }

  PhotoProject? byId(String id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);

    _items.clear();

    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _items.addAll(
            decoded
                .whereType<Map>()
                .map((e) => PhotoProject.fromJson(Map<String, dynamic>.from(e))),
          );
        }
      } catch (_) {}
    }

    _sortItems();
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_items.map((e) => e.toJson()).toList());
    await prefs.setString(_prefsKey, encoded);
  }

  Future<void> addProject(PhotoProject project) async {
    _items.add(project);
    _sortItems();
    await save();
    notifyListeners();
  }

  Future<void> deleteProject(String id) async {
    _items.removeWhere((item) => item.id == id);
    await save();
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final current = _items[index];
    _items[index] = current.copyWith(isFavorite: !current.isFavorite);

    await save();
    notifyListeners();
  }

  Future<void> updateStatus(String id, ProjectStatus status) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final current = _items[index];
    _items[index] = current.copyWith(status: status);

    _sortItems();
    await save();
    notifyListeners();
  }

  Future<void> updateProjectNotes(
    String id, {
    required String description,
    required String beforeNote,
    required String afterNote,
  }) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final current = _items[index];

    _items[index] = current.copyWith(
      description: description,
      beforeNote: beforeNote,
      afterNote: afterNote,
    );

    await save();
    notifyListeners();
  }

  Future<void> updateDuringPhoto(
    String projectId,
    String duringPhotoId, {
    required String note,
    DateTime? date,
  }) async {
    final projectIndex = _items.indexWhere((item) => item.id == projectId);
    if (projectIndex == -1) return;

    final current = _items[projectIndex];
    final updatedDuringPhotos = current.duringPhotos.map((photo) {
      if (photo.id != duringPhotoId) return photo;

      return DuringPhoto(
        id: photo.id,
        path: photo.path,
        note: note,
        date: date,
      );
    }).toList();

    _items[projectIndex] = current.copyWith(
      duringPhotos: updatedDuringPhotos,
    );

    await save();
    notifyListeners();
  }

  Future<void> updateProjectCompletion(
    String id, {
    String? afterPath,
    DateTime? afterDate,
    String? afterNote,
    List<DuringPhoto>? additionalDuringPhotos,
  }) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final current = _items[index];

    final mergedDuring = [
      ...current.duringPhotos,
      ...?additionalDuringPhotos,
    ];

    final effectiveAfterPath = afterPath ?? current.afterPath;
    final newStatus = effectiveAfterPath.trim().isNotEmpty
        ? ProjectStatus.done
        : ProjectStatus.inProgress;

    _items[index] = current.copyWith(
      afterPath: effectiveAfterPath,
      afterDate: afterDate ?? current.afterDate,
      afterNote: afterNote ?? current.afterNote,
      duringPhotos: mergedDuring,
      status: newStatus,
    );

    _sortItems();
    await save();
    notifyListeners();
  }

  void _sortItems() {
    _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}

class LocalFiles {
  static String slug(String title) {
    final lower = title.toLowerCase();
    final normalized = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final collapsed = normalized.replaceAll(RegExp(r'_+'), '_');
    final trimmed = collapsed.replaceAll(RegExp(r'^_|_$'), '');
    final limited = trimmed.length > 40 ? trimmed.substring(0, 40) : trimmed;
    return limited.isEmpty ? 'project' : limited;
  }

  static Future<Directory> projectFolder(String id, String title) async {
    final root = await getApplicationDocumentsDirectory();
    final projectsDir = Directory('${root.path}${Platform.pathSeparator}projects');
    if (!projectsDir.existsSync()) {
      await projectsDir.create(recursive: true);
    }

    final folderName = '${id}_${slug(title)}';
    final folder = Directory(
      '${projectsDir.path}${Platform.pathSeparator}$folderName',
    );

    if (!folder.existsSync()) {
      await folder.create(recursive: true);
    }

    return folder;
  }

  static Future<String> copyXFileToProject(
    Directory projectFolder,
    XFile xfile,
    String label,
  ) async {
    final destinationPath =
        '${projectFolder.path}${Platform.pathSeparator}$label.jpg';
    final bytes = await xfile.readAsBytes();
    final file = File(destinationPath);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static bool fileExists(String path) {
    if (path.trim().isEmpty) return false;
    return File(path).existsSync();
  }

  static Directory? folderFromBeforePath(String beforePath) {
    if (beforePath.trim().isEmpty) return null;
    final file = File(beforePath);
    return file.parent;
  }

  static String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
}