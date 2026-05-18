import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/strings.dart';
import 'user_scope.dart';

/// Morning ritual — 3 quick prompts per day: mood, main goal, gratitude.
/// Stores last 30 days to power analytics / streaks later.
class MorningRitualEntry {
  final String date; // yyyy-MM-dd
  final int mood;    // 1..5
  final String mainGoal;
  final String gratitude;
  MorningRitualEntry({
    required this.date,
    required this.mood,
    required this.mainGoal,
    required this.gratitude,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'mood': mood,
        'mainGoal': mainGoal,
        'gratitude': gratitude,
      };
  static MorningRitualEntry fromJson(Map<String, dynamic> j) =>
      MorningRitualEntry(
        date: j['date'] ?? '',
        mood: (j['mood'] as num?)?.toInt() ?? 3,
        mainGoal: j['mainGoal'] ?? '',
        gratitude: j['gratitude'] ?? '',
      );
}

class MorningRitual {
  static const _keyBase = 'motivai_morning_ritual_v1';
  static String get _key => UserScope.key(_keyBase);
  static List<MorningRitualEntry> _cache = [];
  static bool _loaded = false;
  static String _loadedFor = '';

  static Future<void> _ensure() async {
    if (_loaded && _loadedFor == UserScope.userId) return;
        _cache = [];
        _loadedFor = UserScope.userId;
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _cache = list
            .map((e) => MorningRitualEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _cache = [];
      }
    }
    _loaded = true;
  }

  static String _today() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  static Future<bool> doneToday() async {
    await _ensure();
    final d = _today();
    return _cache.any((e) => e.date == d);
  }

  static Future<MorningRitualEntry?> todaysEntry() async {
    await _ensure();
    final d = _today();
    final list = _cache.where((e) => e.date == d).toList();
    return list.isEmpty ? null : list.first;
  }

  static Future<List<MorningRitualEntry>> recent(int days) async {
    await _ensure();
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _cache.where((e) {
      try {
        final d = DateTime.parse(e.date);
        return d.isAfter(cutoff);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  static Future<void> save(MorningRitualEntry entry) async {
    await _ensure();
    _cache.removeWhere((e) => e.date == entry.date);
    _cache.add(entry);
    // Keep last 60 days
    if (_cache.length > 60) {
      _cache = _cache.sublist(_cache.length - 60);
    }
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _key, jsonEncode(_cache.map((e) => e.toJson()).toList()));
  }

  static List<String> moodEmojis = const [
    '\u{1F622}', // 1 sad
    '\u{1F615}', // 2 meh
    '\u{1F610}', // 3 neutral
    '\u{1F60A}', // 4 good
    '\u{1F929}', // 5 amazing
  ];

  /// Localized prompt strings for the 3-step morning ritual.
  static String get promptMood => S.tr(
        '1. Kayfiyatingiz qanday?',
        '1. Какое у вас настроение?',
        '1. How is your mood?',
      );

  static String get promptGoal => S.tr(
        '2. Bugungi asosiy maqsadingiz?',
        '2. Какова ваша главная цель сегодня?',
        '2. What is your main goal today?',
      );

  static String get promptGratitude => S.tr(
        '3. Nima uchun minnatdorsiz?',
        '3. За что вы благодарны?',
        '3. What are you grateful for?',
      );
}
