import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../config/constants.dart';
import 'api.dart';
import 'coins_storage.dart';
import 'flashcards_storage.dart';
import 'friends_storage.dart';
import 'habit_storage.dart';
import 'journey_storage.dart';
import 'pinned_storage.dart';
import 'rituals_storage.dart';
import 'streak_storage.dart';
import 'user_scope.dart';

/// Cross-device sync of all "local-only" state (coins, habits, flashcards,
/// rituals, journey, pinned task ids, friends list, streak freezes…).
///
/// One backend endpoint stores an opaque JSON blob per user. On login we
/// pull the blob and distribute it to the individual local storages; any
/// time a storage mutates, it calls [schedule] which debounces a push so
/// the server stays roughly in sync without flooding the network.
///
/// Tasks/plans/leaderboard/XP/level live entirely on the backend already
/// — they are intentionally NOT included here.
class UserDataSync {
  UserDataSync._();

  static final Api _api = Api();

  /// 2-second debounce — fast enough that the user perceives writes as
  /// "instant", slow enough that we don't burn battery on every tap.
  static const Duration _debounce = Duration(seconds: 2);

  static Timer? _debounceTimer;

  /// Token-style guard: if a [pullAndApply] is in flight, scheduled
  /// pushes wait until it finishes. Stops the local in-flight push from
  /// trampling the freshly-arrived server state.
  static bool _pulling = false;

  /// True once a successful pull has happened for the current user. Until
  /// then we don't push — otherwise on a fresh install the empty local
  /// state would clobber the server blob.
  static bool _pullCompleted = false;

  /// Per-user marker so a logout/login pair re-arms [_pullCompleted].
  static String _initFor = '';

  /// Reset state when the active user changes (login/logout).
  static void resetForUser() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _pullCompleted = false;
    _initFor = '';
  }

  // ─── PULL ─────────────────────────────────────────────────────────

  /// Fetch the blob from the server and distribute to local storages.
  /// Safe to call without a network — failures are logged and the local
  /// state is left untouched.
  static Future<void> pullAndApply() async {
    final scopeAtStart = UserScope.userId;
    _pulling = true;
    try {
      final res = await _api.get(K.userData);
      // Backend: { success, data: <blob>, updated_at }
      final data = (res is Map) ? res['data'] : null;
      if (data is! Map) {
        // Empty blob (first sync ever for this user) — nothing to apply.
        _pullCompleted = true;
        _initFor = scopeAtStart;
        return;
      }
      await _applyBlob(data.cast<String, dynamic>());
      _pullCompleted = true;
      _initFor = scopeAtStart;
    } catch (e) {
      // Offline / network error — fall back to whatever is on disk. We
      // still flip _pullCompleted because the user might be offline for
      // a while; we don't want to permanently block pushes.
      debugPrint('UserDataSync.pullAndApply failed: $e');
      _pullCompleted = false;
    } finally {
      _pulling = false;
    }
  }

  static Future<void> _applyBlob(Map<String, dynamic> blob) async {
    Future<void> safe(Future<void> Function() body, String label) async {
      try {
        await body();
      } catch (e) {
        debugPrint('UserDataSync.import[$label] failed: $e');
      }
    }

    if (blob.containsKey('coins')) {
      await safe(() => CoinsStorage.importJson(blob['coins']), 'coins');
    }
    if (blob.containsKey('habits')) {
      await safe(() => HabitStorage.importJson(blob['habits']), 'habits');
    }
    if (blob.containsKey('flashcards')) {
      await safe(
          () => FlashcardsStorage.importJson(blob['flashcards']), 'flashcards');
    }
    if (blob.containsKey('rituals')) {
      await safe(
          () => RitualsStorage.importJson(blob['rituals']), 'rituals');
    }
    if (blob.containsKey('journey')) {
      await safe(
          () => JourneyStorage.importJson(blob['journey']), 'journey');
    }
    if (blob.containsKey('pinned')) {
      await safe(
          () => PinnedStorage.importJson(blob['pinned']), 'pinned');
    }
    if (blob.containsKey('friends')) {
      await safe(
          () => FriendsStorage.importJson(blob['friends']), 'friends');
    }
    if (blob.containsKey('streak_freeze')) {
      await safe(
          () => StreakStorage.importJson(blob['streak_freeze']),
          'streak_freeze');
    }
  }

  // ─── PUSH ─────────────────────────────────────────────────────────

  /// Enqueue a push. Coalesces with any other [schedule] call within the
  /// next 2 seconds — only the last one fires.
  static void schedule() {
    if (UserScope.userId == 'anon') return; // not logged in
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () {
      // ignore: discarded_futures
      _pushAll();
    });
  }

  /// Force an immediate push (e.g. on app pause). Awaits the network
  /// call so the caller can `await` for "really, really flush this now".
  static Future<void> flush() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    if (UserScope.userId == 'anon') return;
    await _pushAll();
  }

  static Future<void> _pushAll() async {
    if (UserScope.userId == 'anon') return;
    if (_pulling) {
      // The server is mid-pull; pushing now would race. Re-arm the
      // debounce so it tries again after the pull settles.
      schedule();
      return;
    }
    if (!_pullCompleted || _initFor != UserScope.userId) {
      // We haven't successfully pulled yet for this user; skip — the
      // local state may be empty and would wipe the server. The next
      // pullAndApply will flip the gate.
      return;
    }

    Map<String, dynamic> blob;
    try {
      blob = await _collectBlob();
    } catch (e) {
      debugPrint('UserDataSync.collect failed: $e');
      return;
    }

    try {
      await _api.put(K.userData, {'data': blob});
    } on AuthError {
      // Token expired — caller will re-login. Drop the push.
      debugPrint('UserDataSync.push: auth expired');
    } catch (e) {
      // Network problem — leave local data alone, retry on next
      // schedule(). Don't reset _pullCompleted: we still hold a valid
      // local state, just couldn't reach the server.
      debugPrint('UserDataSync.push failed: $e');
    }
  }

  static Future<Map<String, dynamic>> _collectBlob() async {
    final results = await Future.wait([
      CoinsStorage.exportJson(),
      HabitStorage.exportJson(),
      FlashcardsStorage.exportJson(),
      RitualsStorage.exportJson(),
      JourneyStorage.exportJson(),
      PinnedStorage.exportJson(),
      FriendsStorage.exportJson(),
      StreakStorage.exportJson(),
    ]);
    final blob = <String, dynamic>{
      'coins': results[0],
      'habits': results[1],
      'flashcards': results[2],
      'rituals': results[3],
      'journey': results[4],
      'pinned': results[5],
      'friends': results[6],
      'streak_freeze': results[7],
    };
    // Encode/decode round-trip catches anything that's accidentally not
    // JSON-serialisable BEFORE we hit the network. If the encode throws,
    // bubble up to _pushAll which logs and skips.
    jsonEncode(blob);
    return blob;
  }
}
