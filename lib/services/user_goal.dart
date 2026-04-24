import 'package:shared_preferences/shared_preferences.dart';

/// User's primary long-term goal, captured at onboarding. The Smart Plan
/// and AI suggestions use this to shape default recommendations.
class UserGoal {
  static const _key = 'motivai_user_goal';
  static const _customKey = 'motivai_user_goal_custom';

  static String? _current;
  static String? _custom;
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
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
      options() => const [
            (
              id: 'exam',
              name: 'Imtihon tayyorgarligi',
              emoji: '\u{1F4DA}',
              desc: 'Test, DSh, sertifikat'
            ),
            (
              id: 'language',
              name: 'Til o\'rganish',
              emoji: '\u{1F310}',
              desc: 'Ingliz, rus, arab, boshqa',
            ),
            (
              id: 'programming',
              name: 'Dasturlash',
              emoji: '\u{1F4BB}',
              desc: 'Web, mobil, AI/ML',
            ),
            (
              id: 'habit',
              name: 'Sog\'lom odatlar',
              emoji: '\u{1F4AA}',
              desc: 'Sport, yoga, meditatsiya',
            ),
            (
              id: 'career',
              name: 'Karyera rivoji',
              emoji: '\u{1F4BC}',
              desc: 'Ish, biznes, rezume',
            ),
            (
              id: 'creative',
              name: 'Ijodiy loyiha',
              emoji: '\u{1F3A8}',
              desc: 'Kitob, dizayn, video',
            ),
            (
              id: 'general',
              name: 'Umumiy o\'sish',
              emoji: '\u{2B50}',
              desc: 'Har xil yo\'nalish',
            ),
          ];
}
