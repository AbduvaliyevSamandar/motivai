import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_scope.dart';

/// Per-user activity timestamps used by SmartReminder to compute the
/// best hour to nudge the user. We keep it dirt-simple: a rolling list
/// of (epoch, hour) tuples, capped at the last 14 days.
///
/// Two event kinds are tracked:
///   - 'open' — every time the dashboard mounts (proxy for app open)
///   - 'done' — every task completion (stronger signal of intent)
///
/// Storage shape (JSON list, scoped per user):
///   [{"t": 1714502400, "k": "done", "h": 14}, ...]
class ActivityTracker {
  static const _baseKey = 'activity_log_v1';
  static String get _key => UserScope.key(_baseKey);

  static const int _maxDays = 14;
  static const int _maxEntries = 500;

  /// Append an event. Trims the log to the last 14 days.
  static Future<void> log(String kind) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    final now = DateTime.now();
    final list = <Map<String, dynamic>>[];
    if (raw != null && raw.isNotEmpty) {
      try {
        final parsed = jsonDecode(raw) as List;
        list.addAll(parsed.cast<Map<String, dynamic>>());
      } catch (_) {}
    }
    list.add({
      't': now.millisecondsSinceEpoch ~/ 1000,
      'k': kind,
      'h': now.hour,
    });
    final cutoff = now
        .subtract(Duration(days: _maxDays))
        .millisecondsSinceEpoch ~/ 1000;
    list.removeWhere((e) => (e['t'] as int) < cutoff);
    if (list.length > _maxEntries) {
      list.removeRange(0, list.length - _maxEntries);
    }
    await p.setString(_key, jsonEncode(list));
  }

  /// Returns hourly activity counts for the last 14 days, weighted
  /// (task completions count 3×, app opens count 1×).
  static Future<List<int>> hourlyHistogram() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    final hist = List<int>.filled(24, 0);
    if (raw == null || raw.isEmpty) return hist;
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      for (final e in list) {
        final h = (e['h'] as int?)?.clamp(0, 23) ?? -1;
        if (h < 0) continue;
        final weight = e['k'] == 'done' ? 3 : 1;
        hist[h] += weight;
      }
    } catch (_) {}
    return hist;
  }

  /// Total samples — used to decide whether we have enough data to
  /// pick a smart hour. Below the threshold, we fall back to a sane
  /// default (9 AM) instead of guessing from a tiny sample.
  static Future<int> sampleCount() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null || raw.isEmpty) return 0;
    try {
      return (jsonDecode(raw) as List).length;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}
