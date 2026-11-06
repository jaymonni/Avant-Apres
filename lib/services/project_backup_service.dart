import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';

import '../models/photo_project.dart';

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
        archive.addFile(ArchiveFile(entryName, bytes.length, bytes));
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
}
