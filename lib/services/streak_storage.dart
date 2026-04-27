import 'package:shared_preferences/shared_preferences.dart';
import 'user_scope.dart';

/// Client-side streak protection ("freeze") — works around the fact that
/// the backend doesn't track streak freezes. Stored in SharedPreferences.
class StreakStorage {
  static const _countKeyBase = 'motivai_streak_freezes';
  static String get _countKey => UserScope.key(_countKeyBase);
  static const _lastGrantKeyBase = 'motivai_streak_freeze_last_grant';
  static String get _lastGrantKey => UserScope.key(_lastGrantKeyBase);
  static const _maxFreezes = 3;

  static Future<int> freezesAvailable() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_countKey) ?? 3; // start with 3 freezes
  }

  static Future<void> setFreezes(int count) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_countKey, count.clamp(0, _maxFreezes));
  }

  static int get maxFreezes => _maxFreezes;

  /// Grant a freeze if 7 days have passed since last grant.
  static Future<bool> maybeGrant() async {
    final p = await SharedPreferences.getInstance();
    final current = p.getInt(_countKey) ?? 3;
    if (current >= _maxFreezes) return false;

    final lastGrant = p.getString(_lastGrantKey);
    final now = DateTime.now();
    if (lastGrant != null) {
      final last = DateTime.tryParse(lastGrant);
      if (last != null && now.difference(last).inDays < 7) {
        return false;
      }
    }
    await p.setInt(_countKey, current + 1);
    await p.setString(_lastGrantKey, now.toIso8601String());
    return true;
  }

  /// Use a freeze (decrement). Returns true if successful.
  static Future<bool> use() async {
    final p = await SharedPreferences.getInstance();
    final current = p.getInt(_countKey) ?? 0;
    if (current <= 0) return false;
    await p.setInt(_countKey, current - 1);
    return true;
  }

  static Future<Duration?> timeUntilNext() async {
    final p = await SharedPreferences.getInstance();
    final lastGrant = p.getString(_lastGrantKey);
    if (lastGrant == null) return Duration.zero;
    final last = DateTime.tryParse(lastGrant);
    if (last == null) return Duration.zero;
    final nextAt = last.add(const Duration(days: 7));
    final diff = nextAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }
}
