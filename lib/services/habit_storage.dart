import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple habit tracker stored client-side.
class Habit {
  final String id;
  final String title;
  final String emoji;
  final DateTime createdAt;
  /// ISO date strings ("2026-04-21") of days completed.
  final Set<String> completedDays;

  Habit({
    required this.id,
    required this.title,
    required this.emoji,
    required this.createdAt,
    Set<String>? completedDays,
  }) : completedDays = completedDays ?? <String>{};

  bool isCompletedToday() {
    return completedDays.contains(_todayKey());
  }

  int currentStreak() {
    var streak = 0;
    var day = DateTime.now();
    while (completedDays.contains(_keyOf(day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'emoji': emoji,
        'createdAt': createdAt.toIso8601String(),
        'completedDays': completedDays.toList(),
      };

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
        id: j['id'] ?? '',
        title: j['title'] ?? '',
        emoji: j['emoji'] ?? '\u{1F3AF}',
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ??
            DateTime.now(),
        completedDays:
            ((j['completedDays'] as List?) ?? []).map((e) => e.toString()).toSet(),
      );

  static String _todayKey() => _keyOf(DateTime.now());
  static String _keyOf(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class HabitStorage {
  static const _key = 'motivai_habits_v1';

  static Future<List<Habit>> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Habit.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<Habit> habits) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _key, jsonEncode(habits.map((h) => h.toJson()).toList()));
  }

  static Future<Habit> add({required String title, String emoji = '\u{1F3AF}'}) async {
    final habits = await load();
    final h = Habit(
      id: 'h_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      emoji: emoji,
      createdAt: DateTime.now(),
    );
    habits.add(h);
    await save(habits);
    return h;
  }

  static Future<void> remove(String id) async {
    final habits = await load();
    habits.removeWhere((h) => h.id == id);
    await save(habits);
  }

  static Future<void> toggleToday(String id) async {
    final habits = await load();
    final h = habits.firstWhere((x) => x.id == id, orElse: () => Habit(
          id: '',
          title: '',
          emoji: '',
          createdAt: DateTime.now(),
        ));
    if (h.id.isEmpty) return;
    final today = Habit._todayKey();
    if (h.completedDays.contains(today)) {
      h.completedDays.remove(today);
    } else {
      h.completedDays.add(today);
    }
    await save(habits);
  }
}
