import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Focus journey — 30-day growing tree.
/// Each productive day (1+ completed task) counts as one sprout.
class JourneyDay {
  final String date; // yyyy-MM-dd
  final int tasksDone;
  final int focusMinutes;
  JourneyDay(
      {required this.date,
      required this.tasksDone,
      required this.focusMinutes});

  Map<String, dynamic> toJson() =>
      {'date': date, 'tasksDone': tasksDone, 'focusMinutes': focusMinutes};
  static JourneyDay fromJson(Map<String, dynamic> j) => JourneyDay(
        date: j['date'] ?? '',
        tasksDone: (j['tasksDone'] as num?)?.toInt() ?? 0,
        focusMinutes: (j['focusMinutes'] as num?)?.toInt() ?? 0,
      );
}

class JourneyStorage {
  static const _key = 'motivai_journey_v1';
  static Map<String, JourneyDay> _cache = {};
  static bool _loaded = false;

  static Future<void> _ensure() async {
    if (_loaded) return;
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw != null) {
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        _cache = m.map(
            (k, v) => MapEntry(k, JourneyDay.fromJson(v as Map<String, dynamic>)));
      } catch (_) {
        _cache = {};
      }
    }
    _loaded = true;
  }

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _key,
        jsonEncode(
            _cache.map((k, v) => MapEntry(k, v.toJson()))));
  }

  static Future<void> recordTaskDone() async {
    await _ensure();
    final k = _dateKey(DateTime.now());
    final prev = _cache[k];
    _cache[k] = JourneyDay(
      date: k,
      tasksDone: (prev?.tasksDone ?? 0) + 1,
      focusMinutes: prev?.focusMinutes ?? 0,
    );
    _trim();
    await _persist();
  }

  static Future<void> recordFocusMinutes(int minutes) async {
    await _ensure();
    final k = _dateKey(DateTime.now());
    final prev = _cache[k];
    _cache[k] = JourneyDay(
      date: k,
      tasksDone: prev?.tasksDone ?? 0,
      focusMinutes: (prev?.focusMinutes ?? 0) + minutes,
    );
    _trim();
    await _persist();
  }

  static void _trim() {
    if (_cache.length <= 120) return;
    final sorted = _cache.keys.toList()..sort();
    final drop = sorted.take(_cache.length - 120);
    for (final k in drop) {
      _cache.remove(k);
    }
  }

  static Future<List<JourneyDay>> last30Days() async {
    await _ensure();
    final now = DateTime.now();
    final List<JourneyDay> out = [];
    for (int i = 29; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final k = _dateKey(DateTime(d.year, d.month, d.day));
      out.add(_cache[k] ??
          JourneyDay(date: k, tasksDone: 0, focusMinutes: 0));
    }
    return out;
  }

  static Future<int> productiveDayCount() async {
    final last = await last30Days();
    return last.where((d) => d.tasksDone > 0 || d.focusMinutes > 0).length;
  }
}
