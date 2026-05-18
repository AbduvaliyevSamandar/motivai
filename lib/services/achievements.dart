import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/colors.dart';
import '../config/strings.dart';
import 'user_scope.dart';

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
  static const _unlockedKeyBase = 'motivai_unlocked_achievements';
  static String get _unlockedKey => UserScope.key(_unlockedKeyBase);

  static List<AchievementDef> get all => [
    AchievementDef(
      id: 'first_task',
      title: S.tr('Birinchi qadam', 'Первый шаг', 'First step'),
      description: S.tr('Birinchi vazifani bajardingiz', 'Вы выполнили первую задачу', 'You completed your first task'),
      emoji: '\u{1F331}',
      rarity: 'common',
      bonusXP: 20,
      unlocked: (s) => s.tasksDone >= 1,
    ),
    AchievementDef(
      id: 'streak_3',
      title: S.tr('3 kunlik streak', '3-дневный streak', '3-day streak'),
      description: S.tr('3 kun ketma-ket vazifa bajardingiz', 'Вы выполняли задачи 3 дня подряд', 'You completed tasks 3 days in a row'),
      emoji: '\u{1F525}',
      rarity: 'common',
      bonusXP: 30,
      unlocked: (s) => s.streak >= 3,
    ),
    AchievementDef(
      id: 'streak_7',
      title: S.tr('Hafta ichida', 'За неделю', 'Within a week'),
      description: S.tr('7 kunlik streak!', '7-дневный streak!', '7-day streak!'),
      emoji: '\u{1F308}',
      rarity: 'rare',
      bonusXP: 60,
      unlocked: (s) => s.streak >= 7,
    ),
    AchievementDef(
      id: 'streak_30',
      title: S.tr('Hech qachon to\'xtamaslik', 'Никогда не останавливаться', 'Never stop'),
      description: S.tr('30 kunlik streak — afsonaviy!', '30-дневный streak — легендарно!', '30-day streak — legendary!'),
      emoji: '\u{1F451}',
      rarity: 'legendary',
      bonusXP: 500,
      unlocked: (s) => s.streak >= 30,
    ),
    AchievementDef(
      id: 'level_5',
      title: S.tr('Tajribali', 'Опытный', 'Experienced'),
      description: S.tr('5-darajaga yetdingiz', 'Вы достигли 5 уровня', 'You reached level 5'),
      emoji: '\u{26A1}',
      rarity: 'common',
      bonusXP: 40,
      unlocked: (s) => s.level >= 5,
    ),
    AchievementDef(
      id: 'level_10',
      title: S.tr('Usta', 'Мастер', 'Master'),
      description: S.tr('10-daraja — yaxshi olib bordingiz', '10 уровень — отличная работа', 'Level 10 — well done'),
      emoji: '\u{1F3C5}',
      rarity: 'rare',
      bonusXP: 100,
      unlocked: (s) => s.level >= 10,
    ),
    AchievementDef(
      id: 'level_25',
      title: S.tr('Elita', 'Элита', 'Elite'),
      description: S.tr('25-daraja — elita safida', '25 уровень — в рядах элиты', 'Level 25 — among the elite'),
      emoji: '\u{1F48E}',
      rarity: 'epic',
      bonusXP: 300,
      unlocked: (s) => s.level >= 25,
    ),
    AchievementDef(
      id: 'level_50',
      title: S.tr('Tanho', 'Уникум', 'One of a kind'),
      description: S.tr('50-daraja — afsonaviy darajada', '50 уровень — легендарный уровень', 'Level 50 — legendary tier'),
      emoji: '\u{1F47D}',
      rarity: 'legendary',
      bonusXP: 1000,
      unlocked: (s) => s.level >= 50,
    ),
    AchievementDef(
      id: 'tasks_10',
      title: S.tr("O'ninchiga keldim", 'Добрался до десятки', 'Made it to ten'),
      description: S.tr('10 ta vazifa bajardingiz', 'Вы выполнили 10 задач', 'You completed 10 tasks'),
      emoji: '\u{1F4AA}',
      rarity: 'common',
      bonusXP: 50,
      unlocked: (s) => s.tasksDone >= 10,
    ),
    AchievementDef(
      id: 'tasks_50',
      title: S.tr('Yarim yuz', 'Полсотни', 'Half a hundred'),
      description: S.tr('50 ta vazifa!', '50 задач!', '50 tasks!'),
      emoji: '\u{1F3AF}',
      rarity: 'rare',
      bonusXP: 150,
      unlocked: (s) => s.tasksDone >= 50,
    ),
    AchievementDef(
      id: 'tasks_100',
      title: S.tr('Yuzinchi', 'Сотый', 'One hundred'),
      description: S.tr('100 ta vazifa — kuchli!', '100 задач — мощно!', '100 tasks — powerful!'),
      emoji: '\u{1F3C6}',
      rarity: 'epic',
      bonusXP: 400,
      unlocked: (s) => s.tasksDone >= 100,
    ),
    AchievementDef(
      id: 'xp_1000',
      title: S.tr('Ming XP', 'Тысяча XP', 'A thousand XP'),
      description: S.tr('1000 XP to\'pladingiz', 'Вы набрали 1000 XP', 'You earned 1000 XP'),
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
