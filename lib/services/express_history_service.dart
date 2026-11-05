import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExpressHistoryItem {
  const ExpressHistoryItem({required this.path, required this.createdAt});
  final String path;
  final DateTime createdAt;
}

class ExpressHistoryService {
  static const _key = 'express_exports_v2';

  static Future<List<ExpressHistoryItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final result = <ExpressHistoryItem>[];
    for (final entry in raw) {
      try {
        final json = jsonDecode(entry) as Map<String, dynamic>;
        final path = json['path'] as String;
        final date = DateTime.parse(json['date'] as String);
        if (await File(path).exists()) {
          result.add(ExpressHistoryItem(path: path, createdAt: date));
        }
      } catch (_) {
        // Ignore invalid or missing legacy entries.
      }
    }
    return result;
  }

  static Future<void> add(File exportedFile) async {
    final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/express_history');
    await dir.create(recursive: true);
    final now = DateTime.now();
    final destination = File('${dir.path}/express_${now.microsecondsSinceEpoch}.png');
    await exportedFile.copy(destination.path);
    final prefs = await SharedPreferences.getInstance();
    final entries = prefs.getStringList(_key) ?? [];
    entries.insert(0, jsonEncode({'path': destination.path, 'date': now.toIso8601String()}));
    await prefs.setStringList(_key, entries);
  }

  static Future<void> delete(ExpressHistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = prefs.getStringList(_key) ?? [];
    entries.removeWhere((entry) {
      try {
        return (jsonDecode(entry) as Map<String, dynamic>)['path'] == item.path;
      } catch (_) {
        return true;
      }
    });
    await prefs.setStringList(_key, entries);
    final file = File(item.path);
    if (await file.exists()) await file.delete();
  }
}
