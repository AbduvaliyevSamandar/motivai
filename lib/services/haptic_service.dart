import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum HapticLevel { off, light, medium, strong }

/// Wraps HapticFeedback calls and scales them by user preference.
/// Use [Haptics.selection], [Haptics.light], [Haptics.medium] etc. everywhere
/// instead of HapticFeedback.* so the user can dial it down in settings.
class Haptics {
  static const _key = 'motivai_haptic_level';
  static HapticLevel _level = HapticLevel.medium;
  static bool _loaded = false;

  static HapticLevel get level => _level;

  static Future<void> load() async {
    if (_loaded) return;
    final p = await SharedPreferences.getInstance();
    final name = p.getString(_key);
    if (name != null) {
      _level = HapticLevel.values.firstWhere(
        (e) => e.name == name,
        orElse: () => HapticLevel.medium,
      );
    }
    _loaded = true;
  }

  static Future<void> set(HapticLevel l) async {
    _level = l;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, l.name);
  }

  static void selection() {
    switch (_level) {
      case HapticLevel.off:
        return;
      case HapticLevel.light:
      case HapticLevel.medium:
        HapticFeedback.selectionClick();
        break;
      case HapticLevel.strong:
        HapticFeedback.lightImpact();
        break;
    }
  }

  static void light() {
    switch (_level) {
      case HapticLevel.off:
        return;
      case HapticLevel.light:
        HapticFeedback.selectionClick();
        break;
      case HapticLevel.medium:
        HapticFeedback.lightImpact();
        break;
      case HapticLevel.strong:
        HapticFeedback.mediumImpact();
        break;
    }
  }

  static void medium() {
    switch (_level) {
      case HapticLevel.off:
        return;
      case HapticLevel.light:
        HapticFeedback.lightImpact();
        break;
      case HapticLevel.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticLevel.strong:
        HapticFeedback.heavyImpact();
        break;
    }
  }

  static void heavy() {
    switch (_level) {
      case HapticLevel.off:
        return;
      case HapticLevel.light:
        HapticFeedback.mediumImpact();
        break;
      case HapticLevel.medium:
      case HapticLevel.strong:
        HapticFeedback.heavyImpact();
        break;
    }
  }

  static ({String name, String desc, String emoji}) info(HapticLevel l) {
    switch (l) {
      case HapticLevel.off:
        return (name: 'O\'chirilgan', desc: 'Titrash yo\'q', emoji: '\u{1F515}');
      case HapticLevel.light:
        return (name: 'Zaif', desc: 'Sezilmas titrash', emoji: '\u{1FAB6}');
      case HapticLevel.medium:
        return (name: 'O\'rta', desc: 'Standart (tavsiya)', emoji: '\u{1F4F3}');
      case HapticLevel.strong:
        return (name: 'Kuchli', desc: 'Kuchliroq zarba', emoji: '\u{26A1}');
    }
  }
}
