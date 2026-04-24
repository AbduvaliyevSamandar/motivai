import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

/// A recurring daily/weekly mini-ritual (e.g. "20 min ingliz har ertalab 07:30").
class Ritual {
  final String id;
  final String title;
  final String emoji;
  final int hour;         // 0-23 in local time
  final int minute;       // 0-59
  final int durationMin;  // how long
  /// Days of week: Dart's DateTime.weekday -> 1..7 (Mon..Sun)
  final List<int> weekdays;
  final bool enabled;
  final String? lastCompleted; // yyyy-MM-dd

  Ritual({
    required this.id,
    required this.title,
    required this.emoji,
    required this.hour,
    required this.minute,
    required this.durationMin,
    required this.weekdays,
    this.enabled = true,
    this.lastCompleted,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'emoji': emoji,
        'hour': hour,
        'minute': minute,
        'durationMin': durationMin,
        'weekdays': weekdays,
        'enabled': enabled,
        'lastCompleted': lastCompleted,
      };

  static Ritual fromJson(Map<String, dynamic> j) => Ritual(
        id: j['id'] ?? '',
        title: j['title'] ?? '',
        emoji: j['emoji'] ?? '\u{1F331}',
        hour: (j['hour'] as num?)?.toInt() ?? 8,
        minute: (j['minute'] as num?)?.toInt() ?? 0,
        durationMin: (j['durationMin'] as num?)?.toInt() ?? 20,
        weekdays: ((j['weekdays'] as List?) ?? [1, 2, 3, 4, 5])
            .map((e) => (e as num).toInt())
            .toList(),
        enabled: j['enabled'] as bool? ?? true,
        lastCompleted: j['lastCompleted'] as String?,
      );

  Ritual copyWith({
    String? title,
    String? emoji,
    int? hour,
    int? minute,
    int? durationMin,
    List<int>? weekdays,
    bool? enabled,
    String? lastCompleted,
  }) =>
      Ritual(
        id: id,
        title: title ?? this.title,
        emoji: emoji ?? this.emoji,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        durationMin: durationMin ?? this.durationMin,
        weekdays: weekdays ?? this.weekdays,
        enabled: enabled ?? this.enabled,
        lastCompleted: lastCompleted ?? this.lastCompleted,
      );

  int get notifIdBase => id.hashCode & 0x7FFFFFF;

  /// Returns the next DateTime this ritual should fire at (starting search
  /// from [from]). Returns null if weekdays is empty.
  DateTime? nextFireAfter(DateTime from) {
    if (weekdays.isEmpty) return null;
    for (var i = 0; i < 8; i++) {
      final cand = DateTime(
        from.year,
        from.month,
        from.day,
        hour,
        minute,
      ).add(Duration(days: i));
      if (!weekdays.contains(cand.weekday)) continue;
      if (cand.isAfter(from)) return cand;
    }
    return null;
  }
}

class RitualsStorage {
  static const _key = 'motivai_rituals_v1';
  static List<Ritual> _cache = [];
  static bool _loaded = false;

  static Future<void> _ensure() async {
    if (_loaded) return;
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _cache = list
            .map((e) => Ritual.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _cache = [];
      }
    }
    _loaded = true;
  }

  static Future<List<Ritual>> all() async {
    await _ensure();
    return List<Ritual>.from(_cache);
  }

  static Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _key, jsonEncode(_cache.map((e) => e.toJson()).toList()));
  }

  static Future<Ritual> create({
    required String title,
    required String emoji,
    required int hour,
    required int minute,
    required int durationMin,
    required List<int> weekdays,
  }) async {
    await _ensure();
    final r = Ritual(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      emoji: emoji,
      hour: hour,
      minute: minute,
      durationMin: durationMin,
      weekdays: weekdays,
    );
    _cache.add(r);
    await _persist();
    await _scheduleRitualNotif(r);
    return r;
  }

  static Future<void> update(Ritual r) async {
    await _ensure();
    final idx = _cache.indexWhere((x) => x.id == r.id);
    if (idx < 0) return;
    // Cancel old notif + schedule new
    await NotificationService.instance.cancel(_cache[idx].notifIdBase);
    _cache[idx] = r;
    await _persist();
    if (r.enabled) await _scheduleRitualNotif(r);
  }

  static Future<void> delete(String id) async {
    await _ensure();
    final idx = _cache.indexWhere((x) => x.id == id);
    if (idx < 0) return;
    await NotificationService.instance.cancel(_cache[idx].notifIdBase);
    _cache.removeAt(idx);
    await _persist();
  }

  static Future<void> recordCompletion(String id) async {
    await _ensure();
    final idx = _cache.indexWhere((x) => x.id == id);
    if (idx < 0) return;
    final today = _todayKey();
    _cache[idx] = _cache[idx].copyWith(lastCompleted: today);
    await _persist();
  }

  static String _todayKey() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  static Future<void> _scheduleRitualNotif(Ritual r) async {
    final at = r.nextFireAfter(DateTime.now());
    if (at == null) return;
    await NotificationService.instance.scheduleAt(
      id: r.notifIdBase,
      title: '${r.emoji} ${r.title}',
      body: 'Vaqt keldi — ${r.durationMin} daqiqa fokus',
      at: at,
    );
  }

  /// Re-schedule all enabled rituals for their next firing slots — call
  /// at app launch so notifications survive reboot.
  static Future<void> rescheduleAll() async {
    await _ensure();
    for (final r in _cache) {
      if (!r.enabled) continue;
      await _scheduleRitualNotif(r);
    }
  }
}
