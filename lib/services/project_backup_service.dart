import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';

import '../models/photo_project.dart';
import '../providers/app_provider.dart';

/// Portable export of project metadata and all referenced photo files.
/// The archive uses relative paths so it can be restored on another device.
class ProjectBackupService {
  static Future<File> createBackup(List<PhotoProject> projects) async {
    final archive = Archive();
    final exported = <Map<String, dynamic>>[];

    for (var projectIndex = 0; projectIndex < projects.length; projectIndex++) {
      final project = projects[projectIndex];
      final metadata = Map<String, dynamic>.from(project.toJson());

      Future<String> addPhoto(String path, String label) async {
        if (path.isEmpty) return '';
        final file = File(path);
        if (!await file.exists()) {
          throw StateError('Photo missing from project: ${project.title} ($label)');
        }
        final bytes = await file.readAsBytes();
        final entryName = 'photos/$projectIndex/$label.jpg';
        archive.addFile(ArchiveFile(entryName, bytes.length, bytes.toList()));
        return entryName;
      }

      metadata['beforePath'] = await addPhoto(project.beforePath, 'before');
      metadata['afterPath'] = await addPhoto(project.afterPath, 'after');
      final during = <Map<String, dynamic>>[];
      for (var i = 0; i < project.duringPhotos.length; i++) {
        final photo = project.duringPhotos[i];
        final entry = Map<String, dynamic>.from(photo.toJson());
        entry['path'] = await addPhoto(photo.path, 'during_$i');
        during.add(entry);
      }
      metadata['duringPhotos'] = during;
      exported.add(metadata);
    }

    final manifest = utf8.encode(jsonEncode({
      'format': 'avant_apres_projects',
      'version': 1,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'projects': exported,
    }));
    archive.addFile(ArchiveFile('manifest.json', manifest.length, manifest));

    final zip = ZipEncoder().encode(archive);
    final directory = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${directory.path}/avant_apres_backup_$stamp.zip');
    await file.writeAsBytes(zip, flush: true);
    return file;
  }
  /// Imports a backup without replacing any existing project.
  /// Only photo entries referenced by the manifest are extracted.
  static Future<int> restoreBackup(File zipFile, AppProvider provider) async {
    final zipBytes = await zipFile.readAsBytes();
    if (zipBytes.length > 500 * 1024 * 1024) {
      throw const FormatException('Backup too large');
    }
    final archive = ZipDecoder().decodeBytes(zipBytes, verify: true);
    final entries = <String, ArchiveFile>{};
    for (final entry in archive.files) {
      if (entry.isFile) entries[entry.name] = entry;
    }
    final manifestEntry = entries['manifest.json'];
    if (manifestEntry == null) throw const FormatException('Missing manifest');
    final decoded = jsonDecode(utf8.decode(manifestEntry.readBytes()));
    if (decoded is! Map || decoded['format'] != 'avant_apres_projects' ||
        decoded['version'] != 1 || decoded['projects'] is! List) {
      throw const FormatException('Unsupported backup');
    }
    final projects = decoded['projects'] as List;
    if (projects.length > 1000) throw const FormatException('Too many projects');

    // Validate every photo reference before touching local storage.
    final requiredEntries = <String>{};
    for (final raw in projects) {
      if (raw is! Map) throw const FormatException('Invalid project');
      final project = Map<String, dynamic>.from(raw);
      final refs = <String>[
        (project['beforePath'] ?? '').toString(),
        (project['afterPath'] ?? '').toString(),
      ];
      final during = project['duringPhotos'];
      if (during is! List) throw const FormatException('Invalid photos');
      for (final item in during) {
        if (item is! Map) throw const FormatException('Invalid photo');
        refs.add((item['path'] ?? '').toString());
      }
      for (final ref in refs) {
        if (ref.isEmpty) continue;
        if (!RegExp(r'^photos/[0-9]+/(before|after|during_[0-9]+)\.jpg
            .hasMatch(ref) || !entries.containsKey(ref)) {
          throw const FormatException('Invalid photo reference');
        }
        requiredEntries.add(ref);
      }
    }

    final root = await getApplicationDocumentsDirectory();
    final restoreDir = Directory(
      '${root.path}/projects/import_${DateTime.now().microsecondsSinceEpoch}',
    );
    await restoreDir.create(recursive: true);
    final paths = <String, String>{};
    try {
      for (final ref in requiredEntries) {
        final bytes = entries[ref]!.readBytes().toList();
        final name = ref.replaceAll('/', '_');
        final file = File('${restoreDir.path}/$name');
        await file.writeAsBytes(bytes, flush: true);
        paths[ref] = file.path;
      }
      var count = 0;
      for (final raw in projects) {
        final data = Map<String, dynamic>.from(raw as Map);
        final originalId = (data['id'] ?? '').toString();
        // Never overwrite or merge an existing project by ID.
        if (originalId.isEmpty || provider.byId(originalId) != null) {
          data['id'] = 'restored_${DateTime.now().microsecondsSinceEpoch}_$count';
        }
        String resolved(Object? value) => paths[(value ?? '').toString()] ?? '';
        data['beforePath'] = resolved(data['beforePath']);
        data['afterPath'] = resolved(data['afterPath']);
        data['duringPhotos'] = (data['duringPhotos'] as List).map((rawPhoto) {
          final photo = Map<String, dynamic>.from(rawPhoto as Map);
          photo['path'] = resolved(photo['path']);
          return photo;
        }).toList();
        await provider.addProject(PhotoProject.fromJson(data));
        count++;
      }
      return count;
    } catch (_) {
      // Keep files if any project was already saved to avoid broken references.
      if (!provider.items.any((p) =>
          p.beforePath.startsWith(restoreDir.path) ||
          p.afterPath.startsWith(restoreDir.path))) {
        await restoreDir.delete(recursive: true);
      }
      rethrow;
    }
  }

}
)
            .hasMatch(ref) || !entries.containsKey(ref)) {
          throw const FormatException('Invalid photo reference');
        }
        requiredEntries.add(ref);
      }
    }

    final root = await getApplicationDocumentsDirectory();
    final restoreDir = Directory(
      '${root.path}/projects/import_${DateTime.now().microsecondsSinceEpoch}',
    );
    await restoreDir.create(recursive: true);
    final paths = <String, String>{};
    try {
      for (final ref in requiredEntries) {
        final bytes = entries[ref]!.readBytes();
        final name = ref.replaceAll('/', '_');
        final file = File('${restoreDir.path}/$name');
        await file.writeAsBytes(bytes, flush: true);
        paths[ref] = file.path;
      }
      var count = 0;
      for (final raw in projects) {
        final data = Map<String, dynamic>.from(raw as Map);
        final originalId = (data['id'] ?? '').toString();
        // Never overwrite or merge an existing project by ID.
        if (originalId.isEmpty || provider.byId(originalId) != null) {
          data['id'] = 'restored_${DateTime.now().microsecondsSinceEpoch}_$count';
        }
        String resolved(Object? value) => paths[(value ?? '').toString()] ?? '';
        data['beforePath'] = resolved(data['beforePath']);
        data['afterPath'] = resolved(data['afterPath']);
        data['duringPhotos'] = (data['duringPhotos'] as List).map((rawPhoto) {
          final photo = Map<String, dynamic>.from(rawPhoto as Map);
          photo['path'] = resolved(photo['path']);
          return photo;
        }).toList();
        await provider.addProject(PhotoProject.fromJson(data));
        count++;
      }
      return count;
    } catch (_) {
      // Keep files if any project was already saved to avoid broken references.
      if (!provider.items.any((p) =>
          p.beforePath.startsWith(restoreDir.path) ||
          p.afterPath.startsWith(restoreDir.path))) {
        await restoreDir.delete(recursive: true);
      }
      rethrow;
    }
  }

}
