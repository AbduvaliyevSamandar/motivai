import 'dart:math' as math;
import '../config/strings.dart';

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
  static Map<String, List<String>> get _templates => {
    'study': [
      S.tr('Kitob / konspekt o\'qish', 'Чтение книги / конспекта', 'Read book / notes'),
      S.tr('Masala yechish', 'Решение задач', 'Solve problems'),
      S.tr('Qayta ishlash / takrorlash', 'Повторение / отработка', 'Review / repeat'),
      S.tr('Mashqlar bajarish', 'Выполнение упражнений', 'Do exercises'),
      S.tr('Qisqacha yozma xulosa', 'Краткое письменное резюме', 'Short written summary'),
    ],
    'code': [
      S.tr('Yangi funksiya yozish', 'Написать новую функцию', 'Write a new function'),
      S.tr('Bug tuzatish / debug', 'Исправление багов / debug', 'Bug fix / debug'),
      S.tr('Test yozish', 'Написание тестов', 'Write tests'),
      S.tr('Refactor', 'Рефакторинг', 'Refactor'),
      S.tr('Dokumentatsiya', 'Документация', 'Documentation'),
    ],
    'creative': [
      S.tr('Ijodiy yozuv / draft', 'Творческий текст / черновик', 'Creative writing / draft'),
      S.tr('Brainstorm', 'Мозговой штурм', 'Brainstorm'),
      S.tr('Rasm / dizayn sketch', 'Рисунок / эскиз дизайна', 'Drawing / design sketch'),
      S.tr('Ko\'rib chiqish va polish', 'Просмотр и доработка', 'Review and polish'),
    ],
    'work': [
      S.tr('Eng muhim 1-vazifa', 'Самая важная 1-я задача', 'Most important task'),
      S.tr('Xatlarga javob', 'Ответ на письма', 'Reply to emails'),
      S.tr('Kichik ishlarni yopish', 'Закрытие мелких дел', 'Close small tasks'),
      S.tr('Keyingi kunlik planlash', 'Планирование на завтра', 'Plan the next day'),
    ],
    'fitness': [
      S.tr('Isinish', 'Разминка', 'Warm-up'),
      S.tr('Asosiy mashq seti', 'Основной комплекс', 'Main exercise set'),
      S.tr('Kardio', 'Кардио', 'Cardio'),
      S.tr('Cho\'zilish', 'Растяжка', 'Stretching'),
    ],
    'language': [
      S.tr('Yangi so\'zlar', 'Новые слова', 'New words'),
      S.tr('Grammar mashqi', 'Упражнение по грамматике', 'Grammar exercise'),
      S.tr('Talaffuz', 'Произношение', 'Pronunciation'),
      S.tr('Tinglash / ko\'rish', 'Аудирование / просмотр', 'Listening / watching'),
    ],
    'general': [
      S.tr('Asosiy ish', 'Основная задача', 'Main task'),
      S.tr('Ikkinchi darajali', 'Второстепенное', 'Secondary'),
      S.tr('Qisqa takrorlash', 'Краткое повторение', 'Quick review'),
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
        title: longBreak
            ? S.tr('Uzun tanaffus', 'Длинный перерыв', 'Long break')
            : S.tr('Tanaffus', 'Перерыв', 'Break'),
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

  static List<({String id, String name, String emoji})> areas() => [
        (id: 'study', name: S.tr('O\'qish', 'Учёба', 'Study'), emoji: '\u{1F4DA}'),
        (id: 'code', name: S.tr('Kod', 'Код', 'Code'), emoji: '\u{1F4BB}'),
        (id: 'creative', name: S.tr('Ijod', 'Творчество', 'Creative'), emoji: '\u{1F3A8}'),
        (id: 'work', name: S.tr('Ish', 'Работа', 'Work'), emoji: '\u{1F4BC}'),
        (id: 'fitness', name: S.tr('Sport', 'Спорт', 'Fitness'), emoji: '\u{1F4AA}'),
        (id: 'language', name: S.tr('Til', 'Язык', 'Language'), emoji: '\u{1F310}'),
        (id: 'general', name: S.tr('Umumiy', 'Общее', 'General'), emoji: '\u{2B50}'),
      ];
}
