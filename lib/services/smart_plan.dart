import 'dart:math' as math;

/// Produces a time-boxed plan from available hours + focus area.
/// Time-block algorithm is a classic top-down: split user hours into
/// 25-50 min blocks interleaved with short pauses + one long break.
class SmartPlan {
  final List<SmartBlock> blocks;
  final int totalMinutes;
  SmartPlan({required this.blocks, required this.totalMinutes});
}

class SmartBlock {
  final String title;
  final int minutes;
  final String kind;       // 'focus' | 'short_break' | 'long_break'
  final String? emoji;
  SmartBlock({
    required this.title,
    required this.minutes,
    required this.kind,
    this.emoji,
  });
}

class SmartPlanner {
  static const _templates = <String, List<String>>{
    'study': [
      'Kitob / konspekt o\'qish',
      'Masala yechish',
      'Qayta ishlash / takrorlash',
      'Mashqlar bajarish',
      'Qisqacha yozma xulosa',
    ],
    'code': [
      'Yangi funksiya yozish',
      'Bug tuzatish / debug',
      'Test yozish',
      'Refactor',
      'Dokumentatsiya',
    ],
    'creative': [
      'Ijodiy yozuv / draft',
      'Brainstorm',
      'Rasm / dizayn sketch',
      'Ko\'rib chiqish va polish',
    ],
    'work': [
      'Eng muhim 1-vazifa',
      'Xatlarga javob',
      'Kichik ishlarni yopish',
      'Keyingi kunlik planlash',
    ],
    'fitness': [
      'Isinish',
      'Asosiy mashq seti',
      'Kardio',
      'Cho\'zilish',
    ],
    'language': [
      'Yangi so\'zlar',
      'Grammar mashqi',
      'Talaffuz',
      'Tinglash / ko\'rish',
    ],
    'general': [
      'Asosiy ish',
      'Ikkinchi darajali',
      'Qisqa takrorlash',
    ],
  };

  static SmartPlan build({
    required int hours,
    required String area,
    bool includePomodoro = true,
  }) {
    final templates = _templates[area] ?? _templates['general']!;
    final totalMin = (hours * 60).clamp(25, 720);
    final blocks = <SmartBlock>[];

    int remaining = totalMin;
    int focusIdx = 0;
    int focusCount = 0;
    final rng = math.Random();

    while (remaining >= 25) {
      // Focus block: 25 or 50 min
      int fLen = remaining >= 60 ? 50 : (remaining >= 30 ? 25 : remaining);
      if (fLen > remaining) fLen = remaining;
      final t = templates[focusIdx % templates.length];
      blocks.add(SmartBlock(
        title: t,
        minutes: fLen,
        kind: 'focus',
        emoji: _areaEmoji(area),
      ));
      remaining -= fLen;
      focusIdx++;
      focusCount++;

      if (remaining <= 0) break;
      if (!includePomodoro) continue;

      // Every 3rd block → long break (15m), else short (5m)
      final longBreak = focusCount % 3 == 0;
      final bLen = longBreak ? 15 : 5;
      if (remaining < bLen) break;
      blocks.add(SmartBlock(
        title: longBreak ? 'Uzun tanaffus' : 'Tanaffus',
        minutes: bLen,
        kind: longBreak ? 'long_break' : 'short_break',
        emoji: longBreak ? '\u{2615}' : '\u{1F9D8}',
      ));
      remaining -= bLen;
      // small jitter so plans don't look identical
      if (rng.nextInt(4) == 0 && focusIdx < templates.length) {
        focusIdx = (focusIdx + 1) % templates.length;
      }
    }
    return SmartPlan(blocks: blocks, totalMinutes: totalMin);
  }

  static String _areaEmoji(String area) {
    switch (area) {
      case 'study':
        return '\u{1F4DA}';
      case 'code':
        return '\u{1F4BB}';
      case 'creative':
        return '\u{1F3A8}';
      case 'work':
        return '\u{1F4BC}';
      case 'fitness':
        return '\u{1F4AA}';
      case 'language':
        return '\u{1F310}';
      default:
        return '\u{2B50}';
    }
  }

  static List<({String id, String name, String emoji})> areas() => const [
        (id: 'study', name: 'O\'qish', emoji: '\u{1F4DA}'),
        (id: 'code', name: 'Kod', emoji: '\u{1F4BB}'),
        (id: 'creative', name: 'Ijod', emoji: '\u{1F3A8}'),
        (id: 'work', name: 'Ish', emoji: '\u{1F4BC}'),
        (id: 'fitness', name: 'Sport', emoji: '\u{1F4AA}'),
        (id: 'language', name: 'Til', emoji: '\u{1F310}'),
        (id: 'general', name: 'Umumiy', emoji: '\u{2B50}'),
      ];
}
