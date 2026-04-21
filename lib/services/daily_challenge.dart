import 'package:shared_preferences/shared_preferences.dart';

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
  static const _completedKey = 'motivai_daily_challenge_completed';
  static const _dateKey = 'motivai_daily_challenge_date';
  static const _progressKey = 'motivai_daily_challenge_progress';

  /// Deterministic challenge by day-of-year — same user gets same challenge daily.
  static DailyChallenge today() {
    final now = DateTime.now();
    final key = int.parse(
      '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}',
    );
    return _pool[key % _pool.length];
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

  static const _pool = <DailyChallenge>[
    DailyChallenge(
      type: ChallengeType.completeN,
      target: 3,
      bonusXP: 50,
      title: '3 ta vazifa',
      description: 'Bugun 3 ta vazifani bajaring',
      emoji: '\u{1F3AF}',
    ),
    DailyChallenge(
      type: ChallengeType.completeN,
      target: 5,
      bonusXP: 100,
      title: '5 ta vazifa',
      description: 'Bugun 5 ta vazifa — kuchli kun!',
      emoji: '\u{1F525}',
    ),
    DailyChallenge(
      type: ChallengeType.focusNMin,
      target: 25,
      bonusXP: 75,
      title: '25 daqiqa fokus',
      description: "Bitta Pomodoro sessiyasi bajar",
      emoji: '\u{1F9E0}',
    ),
    DailyChallenge(
      type: ChallengeType.focusNMin,
      target: 60,
      bonusXP: 150,
      title: '1 soat fokus',
      description: 'Ikki Pomodoro — tom ma\'noda',
      emoji: '\u{1F4AA}',
    ),
    DailyChallenge(
      type: ChallengeType.completeN,
      target: 2,
      bonusXP: 30,
      title: '2 ta vazifa',
      description: 'Past bo\'sag\'a — keling shirin start',
      emoji: '\u{2728}',
    ),
    DailyChallenge(
      type: ChallengeType.streakKeep,
      target: 1,
      bonusXP: 40,
      title: 'Streak saqlash',
      description: 'Kamida 1 vazifa — streak uchun',
      emoji: '\u{1F525}',
    ),
    DailyChallenge(
      type: ChallengeType.completeN,
      target: 4,
      bonusXP: 80,
      title: '4 ta vazifa',
      description: "To'rt burchakli kun",
      emoji: '\u{1F3C6}',
    ),
    DailyChallenge(
      type: ChallengeType.focusNMin,
      target: 45,
      bonusXP: 120,
      title: '45 daqiqa fokus',
      description: 'Chuqur ish — tanaffussiz',
      emoji: '\u{1F52C}',
    ),
  ];
}
