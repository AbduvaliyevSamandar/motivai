import 'package:flutter/foundation.dart';

/// All on-device caches and key/value stores must be scoped to the
/// currently signed-in user — otherwise data leaks between accounts that
/// share a phone (e.g. coins, notifications, chat history).
///
/// The pattern:
///   final p = await SharedPreferences.getInstance();
///   final raw = p.getString(UserScope.key('motivai_coins_v1'));
///
/// On login/logout, `UserScope.setUser(...)` should be called and any
/// service holding in-memory cache should subscribe to [UserScope.changes]
/// to clear it.
class UserScope extends ChangeNotifier {
  UserScope._();
  static final UserScope changes = UserScope._();

  static String _userId = 'anon';

  /// The current user's id (or 'anon' before login). Used as a suffix on
  /// every per-user storage key.
  static String get userId => _userId;

  /// Returns a scoped key, e.g. `key('motivai_coins') ->
  /// 'motivai_coins::abc123'`. The double-colon separator avoids clashing
  /// with hyphens that may appear inside the base key.
  static String key(String base) => '$base::$_userId';

  static void setUser(String? id) {
    final next = (id == null || id.isEmpty) ? 'anon' : id;
    if (next == _userId) return;
    _userId = next;
    changes.notifyListeners();
  }
}
