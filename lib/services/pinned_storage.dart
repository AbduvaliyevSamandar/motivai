import 'package:shared_preferences/shared_preferences.dart';

/// Pinned/favorite task IDs — stored locally, shown at the top of the list.
class PinnedStorage {
  static const _key = 'motivai_pinned_tasks_v1';

  static Future<Set<String>> load() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_key) ?? const []).toSet();
  }

  static Future<bool> isPinned(String taskId) async {
    final s = await load();
    return s.contains(taskId);
  }

  static Future<void> toggle(String taskId) async {
    final p = await SharedPreferences.getInstance();
    final current = (p.getStringList(_key) ?? const []).toSet();
    if (current.contains(taskId)) {
      current.remove(taskId);
    } else {
      current.add(taskId);
    }
    await p.setStringList(_key, current.toList());
  }

  static Future<void> remove(String taskId) async {
    final p = await SharedPreferences.getInstance();
    final current = (p.getStringList(_key) ?? const []).toSet();
    current.remove(taskId);
    await p.setStringList(_key, current.toList());
  }
}
