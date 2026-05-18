import '../models/models.dart';
import '../../config/strings.dart';

/// Client-side fallback when AI is unavailable (quota, offline, etc).
/// Provides curated task suggestions based on keyword matching.
class TaskTemplates {
  /// Detect user intent and return relevant suggestions.
  /// Returns empty list when no intent detected.
  static List<TaskSuggestion> suggestFor(String userMessage) {
    final msg = userMessage.toLowerCase();

    // Keyword → category map (Uzbek + English + Russian)
    final matches = <_Bucket>[];

    if (_has(msg, ['matem', 'math', 'матем'])) {
      matches.add(_buckets['math']!);
    }
    if (_has(msg, ['fizika', 'phys', 'физика'])) {
      matches.add(_buckets['physics']!);
    }
    if (_has(msg, ['dastur', 'program', 'cod', 'програм'])) {
      matches.add(_buckets['coding']!);
    }
    if (_has(msg, ['ingliz', 'english', 'англ'])) {
      matches.add(_buckets['english']!);
    }
    if (_has(msg, ['kimyo', 'chem', 'хими'])) {
      matches.add(_buckets['chemistry']!);
    }
    if (_has(msg, ['biolog', 'bio', 'биоло'])) {
      matches.add(_buckets['biology']!);
    }
    if (_has(msg, ['tarix', 'histor', 'истори'])) {
      matches.add(_buckets['history']!);
    }
    if (_has(msg, ['sport', 'jism', 'yurish', 'yugur', 'спорт'])) {
      matches.add(_buckets['exercise']!);
    }
    if (_has(msg, ['kitob', 'book', 'read', 'книг'])) {
      matches.add(_buckets['reading']!);
    }
    if (_has(msg, ['medit', 'meditat', 'медит', 'yoga'])) {
      matches.add(_buckets['meditation']!);
    }

    // If nothing matched but user asked for tasks, give a general starter pack
    if (matches.isEmpty &&
        _has(msg, ['vazifa', 'task', 'rejoy', 'reja', 'plan'])) {
      matches.add(_buckets['starter']!);
    }

    if (matches.isEmpty) return const [];

    // Merge all matching buckets, dedupe by title, take up to 6
    final seen = <String>{};
    final merged = <TaskSuggestion>[];
    for (final b in matches) {
      for (final s in b.items) {
        if (seen.add(s.title)) {
          merged.add(_clone(s, selected: false));
          if (merged.length >= 6) break;
        }
      }
      if (merged.length >= 6) break;
    }
    return merged;
  }

  /// A general-purpose "starter pack" always available.
  static List<TaskSuggestion> starter() =>
      _buckets['starter']!.items.map((s) => _clone(s)).toList();

  static bool _has(String s, List<String> keys) =>
      keys.any((k) => s.contains(k));

  static TaskSuggestion _clone(TaskSuggestion s, {bool selected = false}) =>
      TaskSuggestion(
        title: s.title,
        description: s.description,
        category: s.category,
        difficulty: s.difficulty,
        durationMinutes: s.durationMinutes,
        estimatedPoints: s.estimatedPoints,
        isSelected: selected,
      );

  static Map<String, _Bucket> get _buckets => {
    'math': _Bucket([
      TaskSuggestion(
        title: S.tr('Algebra: 20 ta masala', 'Алгебра: 20 задач', 'Algebra: 20 problems'),
        description: S.tr('Tenglama va tengsizliklar', 'Уравнения и неравенства', 'Equations and inequalities'),
        category: 'study',
        difficulty: 'medium',
        durationMinutes: 45,
        estimatedPoints: 60,
      ),
      TaskSuggestion(
        title: S.tr('Geometriya: teoremalar', 'Геометрия: теоремы', 'Geometry: theorems'),
        description: S.tr('3 ta teorema isboti', 'Доказательство 3 теорем', 'Prove 3 theorems'),
        category: 'study',
        difficulty: 'hard',
        durationMinutes: 60,
        estimatedPoints: 80,
      ),
      TaskSuggestion(
        title: S.tr('Arifmetika amaliyot', 'Арифметика: практика', 'Arithmetic practice'),
        description: S.tr('Zudlik arifmetika 30 misol', 'Быстрая арифметика, 30 примеров', 'Quick arithmetic, 30 examples'),
        category: 'study',
        difficulty: 'easy',
        durationMinutes: 20,
        estimatedPoints: 30,
      ),
    ]),
    'physics': _Bucket([
      TaskSuggestion(
        title: S.tr('Mexanika: Nyuton qonunlari', 'Механика: законы Ньютона', 'Mechanics: Newton\'s laws'),
        description: S.tr('3 ta qonunni takrorlash va misol', 'Повторить 3 закона и примеры', 'Review 3 laws with examples'),
        category: 'study',
        difficulty: 'medium',
        durationMinutes: 40,
        estimatedPoints: 55,
      ),
      TaskSuggestion(
        title: S.tr('Fizika masalalari (5 ta)', 'Задачи по физике (5 шт)', 'Physics problems (5)'),
        description: S.tr('Kinematika yoki dinamika', 'Кинематика или динамика', 'Kinematics or dynamics'),
        category: 'study',
        difficulty: 'hard',
        durationMinutes: 50,
        estimatedPoints: 70,
      ),
    ]),
    'coding': _Bucket([
      TaskSuggestion(
        title: S.tr('LeetCode 2 ta easy', '2 лёгкие задачи на LeetCode', '2 easy LeetCode problems'),
        description: S.tr('Algoritmik fikrlashni rivojlantirish', 'Развитие алгоритмического мышления', 'Develop algorithmic thinking'),
        category: 'productivity',
        difficulty: 'medium',
        durationMinutes: 45,
        estimatedPoints: 60,
      ),
      TaskSuggestion(
        title: S.tr('Proyekt kodni o\'qib chiqish', 'Чтение кода проекта', 'Read project code'),
        description: S.tr('30 daqiqa open-source kod tahlili', '30 минут анализа open-source кода', '30 min open-source code review'),
        category: 'productivity',
        difficulty: 'medium',
        durationMinutes: 30,
        estimatedPoints: 40,
      ),
      TaskSuggestion(
        title: S.tr('Yangi texnologiya o\'rganish', 'Изучить новую технологию', 'Learn a new technology'),
        description: S.tr('1 soat hujjat + namuna', '1 час: документация + пример', '1 hour: docs + sample'),
        category: 'productivity',
        difficulty: 'hard',
        durationMinutes: 60,
        estimatedPoints: 85,
      ),
    ]),
    'english': _Bucket([
      TaskSuggestion(
        title: S.tr('15 ta yangi so\'z yodlash', 'Выучить 15 новых слов', 'Memorize 15 new words'),
        description: S.tr('Flashcards bilan mashq', 'Тренировка с карточками', 'Practice with flashcards'),
        category: 'study',
        difficulty: 'easy',
        durationMinutes: 20,
        estimatedPoints: 30,
      ),
      TaskSuggestion(
        title: S.tr('Ingliz tilida 20 daqiqa eshitish', '20 минут аудирования по-английски', '20 min English listening'),
        description: S.tr('Podcast yoki video', 'Подкаст или видео', 'Podcast or video'),
        category: 'study',
        difficulty: 'medium',
        durationMinutes: 20,
        estimatedPoints: 35,
      ),
      TaskSuggestion(
        title: S.tr('Speaking: 5 daqiqa o\'zingga gapirish', 'Speaking: 5 минут разговора с собой', 'Speaking: 5 min self-talk'),
        description: S.tr('Bugungi kunni inglizcha ifodalash', 'Описать сегодняшний день по-английски', 'Describe your day in English'),
        category: 'study',
        difficulty: 'medium',
        durationMinutes: 10,
        estimatedPoints: 25,
      ),
    ]),
    'chemistry': _Bucket([
      TaskSuggestion(
        title: S.tr('Kimyoviy formulalar takrori', 'Повторение химических формул', 'Chemistry formulas review'),
        description: S.tr('10 ta asosiy formulani yodlash', 'Выучить 10 основных формул', 'Memorize 10 key formulas'),
        category: 'study',
        difficulty: 'medium',
        durationMinutes: 30,
        estimatedPoints: 40,
      ),
    ]),
    'biology': _Bucket([
      TaskSuggestion(
        title: S.tr('Biologik tushunchalar', 'Биологические понятия', 'Biology concepts'),
        description: S.tr('1 bob konspekt', 'Конспект 1 главы', 'Outline 1 chapter'),
        category: 'reading',
        difficulty: 'medium',
        durationMinutes: 45,
        estimatedPoints: 55,
      ),
    ]),
    'history': _Bucket([
      TaskSuggestion(
        title: S.tr('Tarix: 1 mavzu xulosasi', 'История: конспект по теме', 'History: 1 topic summary'),
        description: S.tr('Yozma qisqa konspekt', 'Краткий письменный конспект', 'Short written outline'),
        category: 'reading',
        difficulty: 'easy',
        durationMinutes: 40,
        estimatedPoints: 45,
      ),
    ]),
    'exercise': _Bucket([
      TaskSuggestion(
        title: S.tr('20 daqiqa yugurish', '20 минут бега', '20 min run'),
        description: S.tr('Yurak-qon tomir salomatlik', 'Здоровье сердца и сосудов', 'Cardiovascular health'),
        category: 'exercise',
        difficulty: 'medium',
        durationMinutes: 20,
        estimatedPoints: 40,
      ),
      TaskSuggestion(
        title: S.tr('30 ta push-up', '30 отжиманий', '30 push-ups'),
        description: S.tr('3 seriyada, 10 tadan', '3 подхода по 10', '3 sets of 10'),
        category: 'exercise',
        difficulty: 'medium',
        durationMinutes: 10,
        estimatedPoints: 30,
      ),
      TaskSuggestion(
        title: S.tr('10000 qadam', '10000 шагов', '10000 steps'),
        description: S.tr('Kun davomida yurish', 'Ходьба в течение дня', 'Walking throughout the day'),
        category: 'exercise',
        difficulty: 'easy',
        durationMinutes: 60,
        estimatedPoints: 50,
      ),
    ]),
    'reading': _Bucket([
      TaskSuggestion(
        title: S.tr('30 daqiqa kitob o\'qish', '30 минут чтения книги', '30 min book reading'),
        description: S.tr('Badiiy yoki ilmiy', 'Художественная или научная', 'Fiction or non-fiction'),
        category: 'reading',
        difficulty: 'easy',
        durationMinutes: 30,
        estimatedPoints: 35,
      ),
      TaskSuggestion(
        title: S.tr('O\'qigan kitobdan konspekt', 'Конспект прочитанной книги', 'Notes from the book read'),
        description: S.tr('Asosiy g\'oyalar xulosasi', 'Краткое изложение основных идей', 'Summary of key ideas'),
        category: 'reading',
        difficulty: 'medium',
        durationMinutes: 20,
        estimatedPoints: 30,
      ),
    ]),
    'meditation': _Bucket([
      TaskSuggestion(
        title: S.tr('10 daqiqa meditatsiya', '10 минут медитации', '10 min meditation'),
        description: S.tr('Diqqatni tinchlantirish', 'Успокоить ум', 'Calm the mind'),
        category: 'meditation',
        difficulty: 'easy',
        durationMinutes: 10,
        estimatedPoints: 25,
      ),
      TaskSuggestion(
        title: S.tr('Nafas mashqlari', 'Дыхательные упражнения', 'Breathing exercises'),
        description: S.tr('4-7-8 texnikasi, 5 daqiqa', 'Техника 4-7-8, 5 минут', '4-7-8 technique, 5 min'),
        category: 'meditation',
        difficulty: 'easy',
        durationMinutes: 5,
        estimatedPoints: 15,
      ),
    ]),
    'starter': _Bucket([
      TaskSuggestion(
        title: S.tr('Bugungi maqsad yozish', 'Записать цель на сегодня', 'Write today\'s goal'),
        description: S.tr('Kun boshida 5 daqiqa reja', '5 минут планирования утром', '5 min morning planning'),
        category: 'productivity',
        difficulty: 'easy',
        durationMinutes: 5,
        estimatedPoints: 15,
      ),
      TaskSuggestion(
        title: S.tr('30 daqiqa kitob o\'qish', '30 минут чтения книги', '30 min book reading'),
        description: S.tr('Bilimlarni boyitish', 'Обогатить знания', 'Enrich your knowledge'),
        category: 'reading',
        difficulty: 'easy',
        durationMinutes: 30,
        estimatedPoints: 35,
      ),
      TaskSuggestion(
        title: S.tr('20 daqiqa sport', '20 минут спорта', '20 min sport'),
        description: S.tr('Jismoniy faollik', 'Физическая активность', 'Physical activity'),
        category: 'exercise',
        difficulty: 'medium',
        durationMinutes: 20,
        estimatedPoints: 40,
      ),
      TaskSuggestion(
        title: S.get('subject_language'),
        description: S.tr('Yangi so\'zlar', 'Новые слова', 'New words'),
        category: 'study',
        difficulty: 'medium',
        durationMinutes: 30,
        estimatedPoints: 45,
      ),
      TaskSuggestion(
        title: S.tr('5 daqiqa meditatsiya', '5 минут медитации', '5 min meditation'),
        description: S.tr('Diqqat mashqi', 'Упражнение на внимание', 'Focus exercise'),
        category: 'meditation',
        difficulty: 'easy',
        durationMinutes: 5,
        estimatedPoints: 15,
      ),
    ]),
  };
}

class _Bucket {
  final List<TaskSuggestion> items;
  _Bucket(this.items);
}
