import '../models/models.dart';

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

  static final Map<String, _Bucket> _buckets = {
    'math': _Bucket([
      TaskSuggestion(
        title: 'Algebra: 20 ta masala',
        description: 'Tenglama va tengsizliklar',
        category: 'study',
        difficulty: 'medium',
        durationMinutes: 45,
        estimatedPoints: 60,
      ),
      TaskSuggestion(
        title: 'Geometriya: teoremalar',
        description: '3 ta teorema isboti',
        category: 'study',
        difficulty: 'hard',
        durationMinutes: 60,
        estimatedPoints: 80,
      ),
      TaskSuggestion(
        title: 'Arifmetika amaliyot',
        description: 'Zudlik arifmetika 30 misol',
        category: 'study',
        difficulty: 'easy',
        durationMinutes: 20,
        estimatedPoints: 30,
      ),
    ]),
    'physics': _Bucket([
      TaskSuggestion(
        title: 'Mexanika: Nyuton qonunlari',
        description: '3 ta qonunni takrorlash va misol',
        category: 'study',
        difficulty: 'medium',
        durationMinutes: 40,
        estimatedPoints: 55,
      ),
      TaskSuggestion(
        title: 'Fizika masalalari (5 ta)',
        description: 'Kinematika yoki dinamika',
        category: 'study',
        difficulty: 'hard',
        durationMinutes: 50,
        estimatedPoints: 70,
      ),
    ]),
    'coding': _Bucket([
      TaskSuggestion(
        title: 'LeetCode 2 ta easy',
        description: 'Algoritmik fikrlashni rivojlantirish',
        category: 'productivity',
        difficulty: 'medium',
        durationMinutes: 45,
        estimatedPoints: 60,
      ),
      TaskSuggestion(
        title: 'Proyekt kodni o\'qib chiqish',
        description: '30 daqiqa open-source kod tahlili',
        category: 'productivity',
        difficulty: 'medium',
        durationMinutes: 30,
        estimatedPoints: 40,
      ),
      TaskSuggestion(
        title: 'Yangi texnologiya o\'rganish',
        description: '1 soat hujjat + namuna',
        category: 'productivity',
        difficulty: 'hard',
        durationMinutes: 60,
        estimatedPoints: 85,
      ),
    ]),
    'english': _Bucket([
      TaskSuggestion(
        title: '15 ta yangi so\'z yodlash',
        description: 'Flashcards bilan mashq',
        category: 'study',
        difficulty: 'easy',
        durationMinutes: 20,
        estimatedPoints: 30,
      ),
      TaskSuggestion(
        title: 'Ingliz tilida 20 daqiqa eshitish',
        description: 'Podcast yoki video',
        category: 'study',
        difficulty: 'medium',
        durationMinutes: 20,
        estimatedPoints: 35,
      ),
      TaskSuggestion(
        title: 'Speaking: 5 daqiqa o\'zingga gapirish',
        description: 'Bugungi kunni inglizcha ifodalash',
        category: 'study',
        difficulty: 'medium',
        durationMinutes: 10,
        estimatedPoints: 25,
      ),
    ]),
    'chemistry': _Bucket([
      TaskSuggestion(
        title: 'Kimyoviy formulalar takrori',
        description: '10 ta asosiy formulani yodlash',
        category: 'study',
        difficulty: 'medium',
        durationMinutes: 30,
        estimatedPoints: 40,
      ),
    ]),
    'biology': _Bucket([
      TaskSuggestion(
        title: 'Biologik tushunchalar',
        description: '1 bob konspekt',
        category: 'reading',
        difficulty: 'medium',
        durationMinutes: 45,
        estimatedPoints: 55,
      ),
    ]),
    'history': _Bucket([
      TaskSuggestion(
        title: 'Tarix: 1 mavzu xulosasi',
        description: 'Yozma qisqa konspekt',
        category: 'reading',
        difficulty: 'easy',
        durationMinutes: 40,
        estimatedPoints: 45,
      ),
    ]),
    'exercise': _Bucket([
      TaskSuggestion(
        title: '20 daqiqa yugurish',
        description: 'Yurak-qon tomir salomatlik',
        category: 'exercise',
        difficulty: 'medium',
        durationMinutes: 20,
        estimatedPoints: 40,
      ),
      TaskSuggestion(
        title: '30 ta push-up',
        description: '3 seriyada, 10 tadan',
        category: 'exercise',
        difficulty: 'medium',
        durationMinutes: 10,
        estimatedPoints: 30,
      ),
      TaskSuggestion(
        title: '10000 qadam',
        description: 'Kun davomida yurish',
        category: 'exercise',
        difficulty: 'easy',
        durationMinutes: 60,
        estimatedPoints: 50,
      ),
    ]),
    'reading': _Bucket([
      TaskSuggestion(
        title: '30 daqiqa kitob o\'qish',
        description: 'Badiiy yoki ilmiy',
        category: 'reading',
        difficulty: 'easy',
        durationMinutes: 30,
        estimatedPoints: 35,
      ),
      TaskSuggestion(
        title: 'O\'qigan kitobdan konspekt',
        description: 'Asosiy g\'oyalar xulosasi',
        category: 'reading',
        difficulty: 'medium',
        durationMinutes: 20,
        estimatedPoints: 30,
      ),
    ]),
    'meditation': _Bucket([
      TaskSuggestion(
        title: '10 daqiqa meditatsiya',
        description: 'Diqqatni tinchlantirish',
        category: 'meditation',
        difficulty: 'easy',
        durationMinutes: 10,
        estimatedPoints: 25,
      ),
      TaskSuggestion(
        title: 'Nafas mashqlari',
        description: '4-7-8 texnikasi, 5 daqiqa',
        category: 'meditation',
        difficulty: 'easy',
        durationMinutes: 5,
        estimatedPoints: 15,
      ),
    ]),
    'starter': _Bucket([
      TaskSuggestion(
        title: 'Bugungi maqsad yozish',
        description: 'Kun boshida 5 daqiqa reja',
        category: 'productivity',
        difficulty: 'easy',
        durationMinutes: 5,
        estimatedPoints: 15,
      ),
      TaskSuggestion(
        title: '30 daqiqa kitob o\'qish',
        description: 'Bilimlarni boyitish',
        category: 'reading',
        difficulty: 'easy',
        durationMinutes: 30,
        estimatedPoints: 35,
      ),
      TaskSuggestion(
        title: '20 daqiqa sport',
        description: 'Jismoniy faollik',
        category: 'exercise',
        difficulty: 'medium',
        durationMinutes: 20,
        estimatedPoints: 40,
      ),
      TaskSuggestion(
        title: 'Til o\'rganish',
        description: 'Yangi so\'zlar',
        category: 'study',
        difficulty: 'medium',
        durationMinutes: 30,
        estimatedPoints: 45,
      ),
      TaskSuggestion(
        title: '5 daqiqa meditatsiya',
        description: 'Diqqat mashqi',
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
