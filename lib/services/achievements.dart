import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/colors.dart';

class AchievementDef {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final String rarity; // common, rare, epic, legendary
  final int bonusXP;
  final bool Function(_Stats s) unlocked;

  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.rarity,
    required this.bonusXP,
    required this.unlocked,
  });

  Color get rarityColor => const {
        'legendary': Color(0xFFFCD34D),
        'epic': Color(0xFFA855F7),
        'rare': Color(0xFF00D9FF),
        'common': Color(0xFF94A3B8),
      }[rarity]!;
}

class _Stats {
  final int level;
  final int streak;
  final int tasksDone;
  final int xp;
  const _Stats({
    required this.level,
    required this.streak,
    required this.tasksDone,
    required this.xp,
  });
}

class AchievementService {
  static const _unlockedKey = 'motivai_unlocked_achievements';

  static final List<AchievementDef> all = [
    AchievementDef(
      id: 'first_task',
      title: 'Birinchi qadam',
      description: 'Birinchi vazifani bajardingiz',
      emoji: '\u{1F331}',
      rarity: 'common',
      bonusXP: 20,
      unlocked: (s) => s.tasksDone >= 1,
    ),
    AchievementDef(
      id: 'streak_3',
      title: '3 kunlik streak',
      description: '3 kun ketma-ket vazifa bajardingiz',
      emoji: '\u{1F525}',
      rarity: 'common',
      bonusXP: 30,
      unlocked: (s) => s.streak >= 3,
    ),
    AchievementDef(
      id: 'streak_7',
      title: 'Hafta ichida',
      description: '7 kunlik streak!',
      emoji: '\u{1F308}',
      rarity: 'rare',
      bonusXP: 60,
      unlocked: (s) => s.streak >= 7,
    ),
    AchievementDef(
      id: 'streak_30',
      title: 'Hech qachon to\'xtamaslik',
      description: '30 kunlik streak — afsonaviy!',
      emoji: '\u{1F451}',
      rarity: 'legendary',
      bonusXP: 500,
      unlocked: (s) => s.streak >= 30,
    ),
    AchievementDef(
      id: 'level_5',
      title: 'Tajribali',
      description: '5-darajaga yetdingiz',
      emoji: '\u{26A1}',
      rarity: 'common',
      bonusXP: 40,
      unlocked: (s) => s.level >= 5,
    ),
    AchievementDef(
      id: 'level_10',
      title: 'Usta',
      description: '10-daraja — yaxshi olib bordingiz',
      emoji: '\u{1F3C5}',
      rarity: 'rare',
      bonusXP: 100,
      unlocked: (s) => s.level >= 10,
    ),
    AchievementDef(
      id: 'level_25',
      title: 'Elita',
      description: '25-daraja — elita safida',
      emoji: '\u{1F48E}',
      rarity: 'epic',
      bonusXP: 300,
      unlocked: (s) => s.level >= 25,
    ),
    AchievementDef(
      id: 'level_50',
      title: 'Tanho',
      description: '50-daraja — afsonaviy darajada',
      emoji: '\u{1F47D}',
      rarity: 'legendary',
      bonusXP: 1000,
      unlocked: (s) => s.level >= 50,
    ),
    AchievementDef(
      id: 'tasks_10',
      title: "O'ninchiga keldim",
      description: '10 ta vazifa bajardingiz',
      emoji: '\u{1F4AA}',
      rarity: 'common',
      bonusXP: 50,
      unlocked: (s) => s.tasksDone >= 10,
    ),
    AchievementDef(
      id: 'tasks_50',
      title: 'Yarim yuz',
      description: '50 ta vazifa!',
      emoji: '\u{1F3AF}',
      rarity: 'rare',
      bonusXP: 150,
      unlocked: (s) => s.tasksDone >= 50,
    ),
    AchievementDef(
      id: 'tasks_100',
      title: 'Yuzinchi',
      description: '100 ta vazifa — kuchli!',
      emoji: '\u{1F3C6}',
      rarity: 'epic',
      bonusXP: 400,
      unlocked: (s) => s.tasksDone >= 100,
    ),
    AchievementDef(
      id: 'xp_1000',
      title: 'Ming XP',
      description: '1000 XP to\'pladingiz',
      emoji: '\u{2B50}',
      rarity: 'rare',
      bonusXP: 100,
      unlocked: (s) => s.xp >= 1000,
    ),
  ];

  static Future<Set<String>> unlockedIds() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_unlockedKey) ?? const []).toSet();
  }

  static Future<List<AchievementDef>> checkNewly({
    required int level,
    required int streak,
    required int tasksDone,
    required int xp,
  }) async {
    final stats = _Stats(
        level: level, streak: streak, tasksDone: tasksDone, xp: xp);
    final already = await unlockedIds();
    final newlyUnlocked = <AchievementDef>[];
    for (final a in all) {
      if (already.contains(a.id)) continue;
      if (a.unlocked(stats)) {
        newlyUnlocked.add(a);
        already.add(a.id);
      }
    }
    if (newlyUnlocked.isNotEmpty) {
      final p = await SharedPreferences.getInstance();
      await p.setStringList(_unlockedKey, already.toList());
    }
    return newlyUnlocked;
  }

  static Future<List<(AchievementDef, bool)>> listWithStatus() async {
    final unlocked = await unlockedIds();
    return all.map((a) => (a, unlocked.contains(a.id))).toList();
  }
}
