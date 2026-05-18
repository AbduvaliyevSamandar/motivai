import 'package:shared_preferences/shared_preferences.dart';
import '../config/strings.dart';
import 'user_scope.dart';

/// User's primary long-term goal, captured at onboarding. The Smart Plan
/// and AI suggestions use this to shape default recommendations.
class UserGoal {
  static const _keyBase = 'motivai_user_goal';
  static String get _key => UserScope.key(_keyBase);
  static const _customKeyBase = 'motivai_user_goal_custom';
  static String get _customKey => UserScope.key(_customKeyBase);

  static String? _current;
  static String? _custom;
  static bool _loaded = false;
  static String _loadedFor = '';

  static Future<void> load() async {
    if (_loaded && _loadedFor == UserScope.userId) return;
    _current = null;
    _custom = null;
    _loadedFor = UserScope.userId;
    final p = await SharedPreferences.getInstance();
    _current = p.getString(_key);
    _custom = p.getString(_customKey);
    _loaded = true;
  }

  static String? get current => _current;
  static String? get custom => _custom;

  static Future<void> set(String id, {String? customText}) async {
    _current = id;
    _custom = customText;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, id);
    if (customText != null && customText.isNotEmpty) {
      await p.setString(_customKey, customText);
    } else {
      await p.remove(_customKey);
    }
  }

  static List<({String id, String name, String emoji, String desc})>
      options() => [
            (
              id: 'exam',
              name: S.tr('Imtihon tayyorgarligi', 'Подготовка к экзамену',
                  'Exam preparation'),
              emoji: '\u{1F4DA}',
              desc: S.tr('Test, DSh, sertifikat', 'Тест, ЕГЭ, сертификат',
                  'Test, exam, certificate'),
            ),
            (
              id: 'language',
              name: S.tr('Til o\'rganish', 'Изучение языка',
                  'Language learning'),
              emoji: '\u{1F310}',
              desc: S.tr('Ingliz, rus, arab, boshqa',
                  'Английский, русский, арабский и др.',
                  'English, Russian, Arabic, more'),
            ),
            (
              id: 'programming',
              name: S.tr('Dasturlash', 'Программирование', 'Programming'),
              emoji: '\u{1F4BB}',
              desc: S.tr('Web, mobil, AI/ML', 'Web, mobile, AI/ML',
                  'Web, mobile, AI/ML'),
            ),
            (
              id: 'habit',
              name: S.tr('Sog\'lom odatlar', 'Здоровые привычки',
                  'Healthy habits'),
              emoji: '\u{1F4AA}',
              desc: S.tr('Sport, yoga, meditatsiya', 'Спорт, йога, медитация',
                  'Sport, yoga, meditation'),
            ),
            (
              id: 'career',
              name: S.tr('Karyera rivoji', 'Карьерный рост',
                  'Career growth'),
              emoji: '\u{1F4BC}',
              desc: S.tr('Ish, biznes, rezume', 'Работа, бизнес, резюме',
                  'Work, business, resume'),
            ),
            (
              id: 'creative',
              name: S.tr('Ijodiy loyiha', 'Творческий проект',
                  'Creative project'),
              emoji: '\u{1F3A8}',
              desc: S.tr('Kitob, dizayn, video', 'Книга, дизайн, видео',
                  'Book, design, video'),
            ),
            (
              id: 'general',
              name: S.tr('Umumiy o\'sish', 'Общий рост', 'General growth'),
              emoji: '\u{2B50}',
              desc: S.tr('Har xil yo\'nalish', 'Разные направления',
                  'Various directions'),
            ),
          ];
}
