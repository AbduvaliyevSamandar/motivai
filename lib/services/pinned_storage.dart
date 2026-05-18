import 'package:shared_preferences/shared_preferences.dart';
import 'user_data_sync.dart';
import 'user_scope.dart';

/// Pinned/favorite task IDs — stored locally, shown at the top of the list.
class PinnedStorage {
  static const _keyBase = 'motivai_pinned_tasks_v1';
  static String get _key => UserScope.key(_keyBase);

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
    UserDataSync.schedule();
  }

  static Future<void> remove(String taskId) async {
    final p = await SharedPreferences.getInstance();
    final current = (p.getStringList(_key) ?? const []).toSet();
    current.remove(taskId);
    await p.setStringList(_key, current.toList());
    UserDataSync.schedule();
  }

  /// Cross-device sync: dump pinned ids as a list of strings.
  static Future<dynamic> exportJson() async {
    final s = await load();
    return s.toList();
  }

  /// Cross-device sync: overwrite local pinned set with server-side data.
  static Future<void> importJson(dynamic json) async {
    if (json is! List) return;
    final ids = json.map((e) => e.toString()).toList();
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_key, ids);
  }
}
