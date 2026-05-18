import 'package:shared_preferences/shared_preferences.dart';
import '../config/strings.dart';
import 'user_scope.dart';

enum ChallengeType {
  completeN, // complete N tasks today
  focusNMin, // focus N minutes today (via pomodoro)
  streakKeep, // keep streak today
}

class DailyChallenge {
  final ChallengeType type;
  final int target;
  final int bonusXP;
  final String title;
  final String description;
  final String emoji;

  const DailyChallenge({
    required this.type,
    required this.target,
    required this.bonusXP,
    required this.title,
    required this.description,
    required this.emoji,
  });
}

class DailyChallengeService {
  static const _completedKeyBase = 'motivai_daily_challenge_completed';
  static String get _completedKey => UserScope.key(_completedKeyBase);
  static const _dateKeyBase = 'motivai_daily_challenge_date';
  static String get _dateKey => UserScope.key(_dateKeyBase);
  static const _progressKeyBase = 'motivai_daily_challenge_progress';
  static String get _progressKey => UserScope.key(_progressKeyBase);

  /// Deterministic challenge by day-of-year — same user gets same challenge daily.
  static DailyChallenge today() {
    final now = DateTime.now();
    final key = int.parse(
      '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}',
    );
    final pool = _pool;
    return pool[key % pool.length];
  }

  static Future<bool> isCompletedToday() async {
    final p = await SharedPreferences.getInstance();
    final date = p.getString(_dateKey);
    if (date != _todayKey()) return false;
    return p.getBool(_completedKey) ?? false;
  }

  static Future<int> progress() async {
    final p = await SharedPreferences.getInstance();
    final date = p.getString(_dateKey);
    if (date != _todayKey()) return 0;
    return p.getInt(_progressKey) ?? 0;
  }

  static Future<void> setProgress(int value) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_dateKey, _todayKey());
    await p.setInt(_progressKey, value);
    final target = today().target;
    if (value >= target) {
      await p.setBool(_completedKey, true);
    }
  }

  /// Increment progress by 1 (used on task complete / focus session end).
  static Future<void> increment({int by = 1}) async {
    final curr = await progress();
    await setProgress(curr + by);
  }

  /// Mark complete and return true if this is first completion today.
  static Future<bool> markComplete() async {
    final already = await isCompletedToday();
    if (already) return false;
    final p = await SharedPreferences.getInstance();
    await p.setString(_dateKey, _todayKey());
    await p.setBool(_completedKey, true);
    return true;
  }

  static String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  static List<DailyChallenge> get _pool => [
    DailyChallenge(
      type: ChallengeType.completeN,
      target: 3,
      bonusXP: 50,
      title: S.tr('3 ta vazifa', '3 задачи', '3 tasks'),
      description: S.tr('Bugun 3 ta vazifani bajaring', 'Выполните 3 задачи сегодня', 'Complete 3 tasks today'),
      emoji: '\u{1F3AF}',
    ),
    DailyChallenge(
      type: ChallengeType.completeN,
      target: 5,
      bonusXP: 100,
      title: S.tr('5 ta vazifa', '5 задач', '5 tasks'),
      description: S.tr('Bugun 5 ta vazifa — kuchli kun!', '5 задач сегодня — мощный день!', '5 tasks today — a strong day!'),
      emoji: '\u{1F525}',
    ),
    DailyChallenge(
      type: ChallengeType.focusNMin,
      target: 25,
      bonusXP: 75,
      title: S.tr('25 daqiqa fokus', '25 минут фокуса', '25 min focus'),
      description: S.tr("Bitta Pomodoro sessiyasi bajar", 'Проведите одну сессию Pomodoro', 'Do one Pomodoro session'),
      emoji: '\u{1F9E0}',
    ),
    DailyChallenge(
      type: ChallengeType.focusNMin,
      target: 60,
      bonusXP: 150,
      title: S.tr('1 soat fokus', '1 час фокуса', '1 hour focus'),
      description: S.tr('Ikki Pomodoro — tom ma\'noda', 'Две Pomodoro — буквально', 'Two Pomodoros — literally'),
      emoji: '\u{1F4AA}',
    ),
    DailyChallenge(
      type: ChallengeType.completeN,
      target: 2,
      bonusXP: 30,
      title: S.tr('2 ta vazifa', '2 задачи', '2 tasks'),
      description: S.tr('Past bo\'sag\'a — keling shirin start', 'Низкий порог — мягкий старт', 'Low bar — a gentle start'),
      emoji: '\u{2728}',
    ),
    DailyChallenge(
      type: ChallengeType.streakKeep,
      target: 1,
      bonusXP: 40,
      title: S.tr('Streak saqlash', 'Сохранить streak', 'Keep the streak'),
      description: S.tr('Kamida 1 vazifa — streak uchun', 'Минимум 1 задача — для streak', 'At least 1 task — for the streak'),
      emoji: '\u{1F525}',
    ),
    DailyChallenge(
      type: ChallengeType.completeN,
      target: 4,
      bonusXP: 80,
      title: S.tr('4 ta vazifa', '4 задачи', '4 tasks'),
      description: S.tr("To'rt burchakli kun", 'Четырёхугольный день', 'A four-cornered day'),
      emoji: '\u{1F3C6}',
    ),
    DailyChallenge(
      type: ChallengeType.focusNMin,
      target: 45,
      bonusXP: 120,
      title: S.tr('45 daqiqa fokus', '45 минут фокуса', '45 min focus'),
      description: S.tr('Chuqur ish — tanaffussiz', 'Глубокая работа — без перерыва', 'Deep work — no breaks'),
      emoji: '\u{1F52C}',
    ),
  ];
}
