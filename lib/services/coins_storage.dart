import 'package:shared_preferences/shared_preferences.dart';
import 'user_scope.dart';

/// In-app currency (coins) — earned from tasks / pomodoro / challenges.
class CoinsStorage {
  static const _baseKey = 'motivai_coins';
  static String get _key => UserScope.key(_baseKey);

  static Future<int> balance() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_key) ?? 0;
  }

  static Future<void> add(int amount) async {
    final p = await SharedPreferences.getInstance();
    final curr = p.getInt(_key) ?? 0;
    await p.setInt(_key, curr + amount);
  }

  /// Returns true if enough balance was available and deducted.
  static Future<bool> spend(int amount) async {
    final p = await SharedPreferences.getInstance();
    final curr = p.getInt(_key) ?? 0;
    if (curr < amount) return false;
    await p.setInt(_key, curr - amount);
    return true;
  }

  /// Amount earned from completing a task, based on difficulty.
  static int taskReward(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return 5;
      case 'medium':
        return 10;
      case 'hard':
        return 15;
      case 'expert':
        return 25;
      default:
        return 8;
    }
  }
}
