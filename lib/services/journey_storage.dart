import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_scope.dart';

/// Focus journey — 30-day growing tree.
/// Each productive day (1+ completed task) counts as one sprout.
class JourneyDay {
  final String date; // yyyy-MM-dd
  final int tasksDone;
  final int focusMinutes;
  /// Hour-of-day histogram for tasks completed (0..23 indexed counts).
  final List<int> hourly;
  JourneyDay({
    required this.date,
    required this.tasksDone,
    required this.focusMinutes,
    List<int>? hourly,
  }) : hourly = hourly ?? List<int>.filled(24, 0);

  Map<String, dynamic> toJson() => {
        'date': date,
        'tasksDone': tasksDone,
        'focusMinutes': focusMinutes,
        'hourly': hourly,
      };
  static JourneyDay fromJson(Map<String, dynamic> j) {
    final rawHour = j['hourly'];
    final hours = List<int>.filled(24, 0);
    if (rawHour is List) {
      for (var i = 0; i < rawHour.length && i < 24; i++) {
        hours[i] = (rawHour[i] as num?)?.toInt() ?? 0;
      }
    }
    return JourneyDay(
      date: j['date'] ?? '',
      tasksDone: (j['tasksDone'] as num?)?.toInt() ?? 0,
      focusMinutes: (j['focusMinutes'] as num?)?.toInt() ?? 0,
      hourly: hours,
    );
  }
}

class JourneyStorage {
  static const _keyBase = 'motivai_journey_v1';
  static String get _key => UserScope.key(_keyBase);
  static Map<String, JourneyDay> _cache = {};
  static bool _loaded = false;
  static String _loadedFor = '';

  static Future<void> _ensure() async {
    if (_loaded && _loadedFor == UserScope.userId) return;
    _cache = {};
    _loadedFor = UserScope.userId;
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
    final now = DateTime.now();
    final k = _dateKey(now);
    final prev = _cache[k];
    final hours = List<int>.from(prev?.hourly ?? List<int>.filled(24, 0));
    final hIdx = now.hour.clamp(0, 23);
    hours[hIdx] = hours[hIdx] + 1;
    _cache[k] = JourneyDay(
      date: k,
      tasksDone: (prev?.tasksDone ?? 0) + 1,
      focusMinutes: prev?.focusMinutes ?? 0,
      hourly: hours,
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
      hourly: prev?.hourly,
    );
    _trim();
    await _persist();
  }

  /// Build a 7-day x 24-hour heatmap (recent week, 0 = Mon … 6 = Sun),
  /// aggregating tasksDone per weekday+hour over the last 8 weeks for
  /// more reliable signal.
  static Future<List<List<int>>> heatmap({int weeks = 8}) async {
    await _ensure();
    final grid = List<List<int>>.generate(
        7, (_) => List<int>.filled(24, 0));
    final cutoff = DateTime.now().subtract(Duration(days: 7 * weeks));
    for (final d in _cache.values) {
      DateTime? parsed;
      try {
        parsed = DateTime.parse(d.date);
      } catch (_) {
        continue;
      }
      if (parsed.isBefore(cutoff)) continue;
      // Dart: Monday == 1, Sunday == 7
      final weekday = (parsed.weekday - 1).clamp(0, 6);
      for (var h = 0; h < 24 && h < d.hourly.length; h++) {
        grid[weekday][h] += d.hourly[h];
      }
    }
    return grid;
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
