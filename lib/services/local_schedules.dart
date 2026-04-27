import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_scope.dart';

/// Client-side task schedule storage.
/// Backend stores only scheduled_time (HH:MM). We store the full DateTime
/// + reminderMinutes locally, keyed by taskId (or title hash if id unknown).
class LocalSchedules {
  static const _keyBase = 'motivai_local_schedules_v1';
  static String get _key => UserScope.key(_keyBase);

  static Future<Map<String, _Entry>> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key);
      if (raw == null || raw.isEmpty) return {};
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) =>
          MapEntry(k, _Entry.fromJson(v as Map<String, dynamic>)));
    } catch (_) {
      return {};
    }
  }

  static Future<void> _save(Map<String, _Entry> m) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
          _key, jsonEncode(m.map((k, v) => MapEntry(k, v.toJson()))));
    } catch (_) {}
  }

  /// Save by task id (preferred).
  static Future<void> saveById({
    required String taskId,
    required DateTime scheduledAt,
    required int reminderMinutes,
  }) async {
    final m = await _load();
    m[taskId] = _Entry(at: scheduledAt, remind: reminderMinutes);
    await _save(m);
  }

  /// Save by temporary key (e.g. title) when task id is unknown yet.
  static Future<void> savePending({
    required String title,
    required DateTime scheduledAt,
    required int reminderMinutes,
  }) async {
    final m = await _load();
    m['pending:$title'] = _Entry(at: scheduledAt, remind: reminderMinutes);
    await _save(m);
  }

  /// Get by task id
  static Future<({DateTime at, int remind})?> getById(String taskId) async {
    final m = await _load();
    final e = m[taskId];
    if (e == null) return null;
    return (at: e.at, remind: e.remind);
  }

  /// Promote a pending:title entry to taskId when we learn the id.
  static Future<void> promotePending({
    required String title,
    required String taskId,
  }) async {
    final m = await _load();
    final pendingKey = 'pending:$title';
    final e = m[pendingKey];
    if (e == null) return;
    m.remove(pendingKey);
    m[taskId] = e;
    await _save(m);
  }

  static Future<void> remove(String taskId) async {
    final m = await _load();
    m.remove(taskId);
    await _save(m);
  }

  static Future<Map<String, ({DateTime at, int remind})>> getAll() async {
    final m = await _load();
    return m.map((k, v) => MapEntry(k, (at: v.at, remind: v.remind)));
  }
}

class _Entry {
  final DateTime at;
  final int remind;
  _Entry({required this.at, required this.remind});
  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'remind': remind,
      };
  factory _Entry.fromJson(Map<String, dynamic> j) => _Entry(
        at: DateTime.tryParse(j['at'] ?? '') ?? DateTime.now(),
        remind: (j['remind'] ?? 15) as int,
      );
}
