import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-task reflections / notes stored locally.
class TaskNotes {
  static const _key = 'motivai_task_notes_v1';

  static Future<Map<String, String>> loadAll() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      return (jsonDecode(raw) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  static Future<String?> get(String taskId) async {
    final m = await loadAll();
    return m[taskId];
  }

  static Future<void> set(String taskId, String note) async {
    final m = await loadAll();
    if (note.trim().isEmpty) {
      m.remove(taskId);
    } else {
      m[taskId] = note.trim();
    }
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(m));
  }

  static Future<void> remove(String taskId) async {
    await set(taskId, '');
  }
}
